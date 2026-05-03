import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, otpHash } from "../_shared/otp.ts";

const MAX_ATTEMPTS = 5;

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
  const pepper = Deno.env.get("OTP_PEPPER");

  if (!supabaseUrl || !anonKey || !serviceKey || !pepper) {
    console.error("Missing env");
    return new Response(
      JSON.stringify({ success: false, message: "Server misconfigured" }),
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

  let body: { phone?: string; otpCode?: string; otp?: string } = {};
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ success: false, message: "Invalid JSON" }),
      { status: 422, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const phone = (body.phone ?? "").trim();
  const rawCode = (body.otpCode ?? body.otp ?? "").trim();
  if (!phone || !rawCode) {
    return new Response(
      JSON.stringify({ success: false, message: "phone and otpCode required" }),
      { status: 422, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const admin = createClient(supabaseUrl, serviceKey);

  const { data: profile, error: profErr } = await admin
    .from("profiles")
    .select("phone")
    .eq("id", uid)
    .maybeSingle();

  if (profErr || !profile?.phone || profile.phone !== phone) {
    return new Response(
      JSON.stringify({ success: false, message: "Phone does not match account" }),
      { status: 403, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const { data: rows, error: rowErr } = await admin
    .from("phone_otps")
    .select("id, code_hash, expires_at, consumed_at, attempt_count")
    .eq("phone", phone)
    .is("consumed_at", null)
    .order("created_at", { ascending: false })
    .limit(1);

  if (rowErr || !rows?.length) {
    return new Response(
      JSON.stringify({ success: false, message: "No active code for this phone" }),
      { status: 400, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const row = rows[0]!;
  if (row.attempt_count >= MAX_ATTEMPTS) {
    return new Response(
      JSON.stringify({ success: false, message: "Too many attempts" }),
      { status: 429, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  if (new Date(row.expires_at) < new Date()) {
    return new Response(
      JSON.stringify({ success: false, message: "Code expired" }),
      { status: 400, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  const expected = await otpHash(pepper, phone, rawCode);
  if (expected !== row.code_hash) {
    await admin
      .from("phone_otps")
      .update({ attempt_count: row.attempt_count + 1 })
      .eq("id", row.id);

    return new Response(
      JSON.stringify({ success: false, message: "Invalid code" }),
      { status: 400, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  await admin.from("phone_otps").update({ consumed_at: new Date().toISOString() }).eq("id", row.id);

  const { error: upErr } = await admin
    .from("profiles")
    .update({ is_verified: true, updated_at: new Date().toISOString() })
    .eq("id", uid);

  if (upErr) {
    console.error(upErr);
    return new Response(
      JSON.stringify({ success: false, message: "Could not update profile" }),
      { status: 500, headers: { ...c, "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({
      success: true,
      message: "Phone verified successfully.",
    }),
    { status: 200, headers: { ...c, "Content-Type": "application/json" } },
  );
});
