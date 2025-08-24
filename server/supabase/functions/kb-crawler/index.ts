// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const PROJECT_URL = Deno.env.get("SUPABASE_URL")!;

async function upsertDoc(doc: any) {
  const resp = await fetch(`${PROJECT_URL}/rest/v1/kb_docs?select=id&source_url=eq.${encodeURIComponent(doc.source_url)}`, {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` },
  });
  const exist = await resp.json();
  if (Array.isArray(exist) && exist.length > 0) return exist[0].id;
  const ins = await fetch(`${PROJECT_URL}/rest/v1/kb_docs`, {
    method: "POST",
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}`, "Content-Type": "application/json", Prefer: "return=representation" },
    body: JSON.stringify([doc]),
  });
  const data = await ins.json();
  return data[0]?.id;
}

async function insertChunks(doc_id: string, chunks: any[]) {
  if (!chunks.length) return;
  await fetch(`${PROJECT_URL}/rest/v1/kb_chunks`, {
    method: "POST",
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}`, "Content-Type": "application/json", Prefer: "return=minimal" },
    body: JSON.stringify(chunks.map((c, i) => ({ doc_id, chunk_index: i, content: c.content, locale: c.locale ?? "en" }))),
  });
}

serve(async (_req) => {
  // Placeholder: fetch a couple of sources and insert as demo
  const now = new Date().toISOString().slice(0,10);
  const demo = {
    title: `Daily snapshot ${now}`,
    abstract: "Automated fetch placeholder",
    tags: ["demo"],
    date: now,
    source_url: `https://example.com/demo/${now}`,
    jurisdiction: "US",
    evidence_level: "summary",
  };
  const id = await upsertDoc(demo);
  if (id) await insertChunks(id, [{ content: "This is a placeholder chunk." }]);
  return new Response("ok");
});


