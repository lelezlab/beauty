import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const url = new URL(req.url);
    const id = url.searchParams.get("id");
    if (!id) return new Response(JSON.stringify({ error: "missing id" }), { status: 400 });
    const r = await fetch(`${SUPABASE_URL}/rest/v1/recon_jobs?id=eq.${id}`, { headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` } });
    const arr = await r.json();
    const row = arr[0] ?? null;
    return new Response(JSON.stringify(row ? { id, status: row.status, outputs: row.outputs, error: row.error } : { error: "not found" }), { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});


