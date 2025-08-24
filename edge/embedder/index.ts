// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const URL = Deno.env.get("SUPABASE_URL")!;
const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

async function fetchChunks(limit = 200) {
  const resp = await fetch(`${URL}/rest/v1/kb_chunks?select=id,content&embedding=is.null&order=created_at.asc&limit=${limit}`, {
    headers: { apikey: SRK, Authorization: `Bearer ${SRK}` },
  });
  return await resp.json();
}

async function embed(texts: string[]): Promise<number[][]> {
  const resp = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "text-embedding-3-small", input: texts }),
  });
  const data = await resp.json();
  return data.data.map((d: any) => d.embedding as number[]);
}

async function updateEmbeddings(items: any[], vecs: number[][]) {
  const rows = items.map((it: any, i: number) => ({ id: it.id, embedding: vecs[i] }));
  await fetch(`${URL}/rest/v1/kb_chunks`, {
    method: "PATCH",
    headers: { apikey: SRK, Authorization: `Bearer ${SRK}`, "Content-Type": "application/json", Prefer: "return=minimal" },
    body: JSON.stringify(rows),
  });
}

serve(async (_req) => {
  const items = await fetchChunks();
  if (!items.length) return new Response(JSON.stringify({ updated: 0 }), { headers: { "Content-Type": "application/json" } });
  const vecs = await embed(items.map((i: any) => i.content));
  await updateEmbeddings(items, vecs);
  return new Response(JSON.stringify({ updated: items.length }), { headers: { "Content-Type": "application/json" } });
});


