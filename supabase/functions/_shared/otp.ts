export async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function otpHash(
  pepper: string,
  phone: string,
  code: string,
): Promise<string> {
  const normalized = phone.trim();
  return sha256Hex(`${pepper}|${normalized}|${code}`);
}

export function randomSixDigit(): string {
  return String(Math.floor(100000 + Math.random() * 900000));
}

export function corsHeaders(origin: string | null): HeadersInit {
  const allow = origin ?? "*";
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}
