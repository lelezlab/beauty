import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const body = await req.json();
    const id = body.job_id as string;
    const meta = body.meta ?? {};
    const inputs = body.inputs ?? {};
    const r = await fetch(`${SUPABASE_URL}/rest/v1/recon_jobs`, {
      method: "POST",
      headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, "Content-Type": "application/json", Prefer: "return=minimal" },
      body: JSON.stringify({ id, device_id: meta.device_id ?? "unknown", mode: meta.mode ?? "triView", status: "queued", inputs })
    });
    if (!r.ok) throw new Error(await r.text());
    // Optionally trigger run here by calling run endpoint
    return new Response(JSON.stringify({ ok: true, id }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});


