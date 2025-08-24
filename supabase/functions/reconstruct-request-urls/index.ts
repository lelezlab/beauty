// Deno Deploy Edge Function: reconstruct-request-urls
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

async function signURL(bucket: string, path: string, method: string) {
  const url = `${SUPABASE_URL}/storage/v1/object/sign/${bucket}/${path}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, "Content-Type": "application/json" },
    body: JSON.stringify({ expiresIn: 60 * 10 })
  });
  const j = await res.json();
  return `${SUPABASE_URL}/storage/v1/${method === "PUT" ? "upload" : "object"}/sign/${bucket}/${path}?token=${j.token}`;
}

serve(async (req) => {
  try {
    const body = await req.json();
    const mode = body.mode ?? "triView";
    const deviceId = body.device_id ?? "unknown";
    const ext = body.ext ?? "jpg";
    const id = crypto.randomUUID();
    const base = `recon-inputs/${id}`;
    const front = `${base}/front.${ext}`;
    const left = `${base}/left.${ext}`;
    const right = `${base}/right.${ext}`;
    const urls = {
      front: await signURL("recon-inputs", front, "PUT"),
      left: await signURL("recon-inputs", left, "PUT"),
      right: await signURL("recon-inputs", right, "PUT"),
    };
    return new Response(JSON.stringify({ job_id: id, upload_urls: urls, inputs: { front_path: front, left_path: left, right_path: right, mode, device: deviceId } }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});


