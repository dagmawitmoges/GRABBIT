import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  corsHeaders,
  otpHash,
  randomSixDigit,
} from "../_shared/otp.ts";

const MAX_SENDS_PER_HOUR = 5;
const OTP_TTL_MINUTES = 5;

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");
  const c = corsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: c });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ success: false, message: "Method not allowed" }), {
      status: 405,
      headers: { ...c, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const twilioToken = Deno.env.get("TWILIO_AUTH_TOKEN");
  const twilioFrom = Deno.env.get("TWILIO_FROM");
  const twilioMsid = Deno.env.get("TWILIO_MESSAGING_SERVICE_SID");
  const pepper = Deno.env.get("OTP_PEPPER");

  if (!supabaseUrl || !anonKey || !serviceKey || !twilioSid || !twilioToken || !pepper) {
    console.error("Missing env: SUPABASE_URL, keys, TWILIO_*, or OTP_PEPPER");
    return new Response(
      JSON.stringify({ success: false, message: "Server misconfigured" }),
      { status: 500, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  if (!twilioFrom && !twilioMsid) {
    console.error("Set TWILIO_FROM or TWILIO_MESSAGING_SERVICE_SID");
    return new Response(
      JSON.stringify({ success: false, message: "Server misconfigured (Twilio sender)" }),
      { status: 500, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ success: false, message: "Authorization required" }),
      { status: 401, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) {
    return new Response(
      JSON.stringify({ success: false, message: "Invalid session" }),
      { status: 401, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const uid = userData.user.id;
  let body: { phone?: string } = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }

  const admin = createClient(supabaseUrl, serviceKey);

  const { data: profile, error: profErr } = await admin
    .from("profiles")
    .select("phone")
    .eq("id", uid)
    .maybeSingle();

  if (profErr) {
    console.error(profErr);
    return new Response(
      JSON.stringify({ success: false, message: "Profile lookup failed" }),
      { status: 500, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  let phone = (body.phone ?? profile?.phone ?? "").trim();
  if (!phone) {
    return new Response(
      JSON.stringify({ success: false, message: "Phone is required" }),
      { status: 422, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  if (profile?.phone && profile.phone !== phone) {
    return new Response(
      JSON.stringify({ success: false, message: "Phone does not match profile" }),
      { status: 403, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  if (!profile?.phone) {
    const { error: upErr } = await admin.from("profiles").update({ phone }).eq("id", uid);
    if (upErr) {
      console.error(upErr);
      return new Response(
        JSON.stringify({ success: false, message: "Could not save phone" }),
        { status: 409, headers: { ...c, "Content-Type": "application/json" } },
      );
    }
  }

  const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count, error: cntErr } = await admin
    .from("phone_otps")
    .select("*", { count: "exact", head: true })
    .eq("phone", phone)
    .gte("created_at", since);

  if (cntErr) {
    console.error(cntErr);
    return new Response(
      JSON.stringify({ success: false, message: "Rate check failed" }),
      { status: 500, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  if ((count ?? 0) >= MAX_SENDS_PER_HOUR) {
    return new Response(
      JSON.stringify({ success: false, message: "Too many codes sent. Try later." }),
      { status: 429, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const code = randomSixDigit();
  const codeHash = await otpHash(pepper, phone, code);
  const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

  const { error: insErr } = await admin.from("phone_otps").insert({
    phone,
    code_hash: codeHash,
    expires_at: expiresAt,
  });

  if (insErr) {
    console.error(insErr);
    return new Response(
      JSON.stringify({ success: false, message: "Could not store OTP" }),
      { status: 500, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const params = new URLSearchParams({ To: phone, Body: `Your Grabbit code is ${code}. It expires in ${OTP_TTL_MINUTES} minutes.` });
  if (twilioMsid) {
    params.set("MessagingServiceSid", twilioMsid);
  } else {
    params.set("From", twilioFrom!);
  }

  const twResp = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: "Basic " + btoa(`${twilioSid}:${twilioToken}`),
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    },
  );

  if (!twResp.ok) {
    const text = await twResp.text();
    console.error("Twilio error:", twResp.status, text);
    return new Response(
      JSON.stringify({ success: false, message: "SMS send failed" }),
      { status: 503, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({
      success: true,
      message: "Verification code sent by SMS.",
    }),
    { status: 200, headers: { ...c, "Content-Type": "application/json" } },
  );
});
