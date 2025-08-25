import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

async function update(id: string, patch: any) {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/recon_jobs?id=eq.${id}`, {
    method: "PATCH",
    headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, "Content-Type": "application/json" },
    body: JSON.stringify(patch)
  });
  if (!r.ok) throw new Error(await r.text());
}

serve(async (_req) => {
  try {
    // fetch one queued job
    const r = await fetch(`${SUPABASE_URL}/rest/v1/recon_jobs?status=eq.queued&select=*&limit=1`, { headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` } });
    const arr = await r.json();
    const job = arr[0];
    if (!job) return new Response(JSON.stringify({ ok: true, picked: 0 }));
    const id = job.id as string;
    await update(id, { status: "running" });

    // mock or triView minimal demo
    const outputsBase = `recon-outputs/${id}`;
    const outputs = {
      mesh_glb: `${outputsBase}/mesh.glb`,
      texture_png: `${outputsBase}/texture.png`,
      landmarks_json: `${outputsBase}/landmarks.json`,
      preview_mp4: `${outputsBase}/preview.mp4`,
      metrics: { rmse: 1.8, views_used: 3 }
    };
    // For first version, write minimal JSON and placeholders (real implementation later)
    await update(id, { status: "done", outputs });
    return new Response(JSON.stringify({ ok: true, id }));
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});


