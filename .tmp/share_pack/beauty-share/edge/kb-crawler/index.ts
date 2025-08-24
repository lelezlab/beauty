// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const URL = Deno.env.get("SUPABASE_URL")!;
const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ADMIN_API_KEY = Deno.env.get("ADMIN_API_KEY")!;
const OPENFDA_API_KEY = Deno.env.get("OPENFDA_API_KEY") ?? "";
const PUBMED_EMAIL = Deno.env.get("PUBMED_EMAIL") ?? "";

async function fetchASPS(): Promise<any[]> { return []; }
async function fetchBAAPS(): Promise<any[]> { return []; }
async function fetchOpenFDA(): Promise<any[]> { return []; }
async function fetchPubMed(): Promise<any[]> { return []; }

function normalize(item: any) {
  return {
    title: item.title?.slice(0, 512) ?? "",
    abstract: item.abstract ?? item.snippet ?? null,
    tags: item.tags ?? [],
    date: item.date ?? new Date().toISOString().slice(0,10),
    source_url: item.url ?? item.source_url,
    jurisdiction: item.jurisdiction ?? null,
    evidence_level: item.evidence_level ?? null,
    locale: item.locale ?? "en",
  };
}

async function upsertDoc(doc: any) {
  // idempotent by source_url + date
  const exist = await fetch(`${URL}/rest/v1/kb_docs?select=id&source_url=eq.${encodeURIComponent(doc.source_url)}&date=eq.${doc.date}`, {
    headers: { apikey: SRK, Authorization: `Bearer ${SRK}` },
  }).then(r => r.json());
  if (Array.isArray(exist) && exist.length) return exist[0].id;
  const ins = await fetch(`${URL}/rest/v1/kb_docs`, {
    method: "POST",
    headers: { apikey: SRK, Authorization: `Bearer ${SRK}`, "Content-Type": "application/json", Prefer: "return=representation" },
    body: JSON.stringify([doc]),
  }).then(r => r.json());
  return ins[0]?.id as string;
}

function chunkText(text: string, size = 800): string[] {
  const out: string[] = [];
  let i = 0; while (i < text.length) { out.push(text.slice(i, i + size)); i += size; }
  return out;
}

async function insertChunks(doc_id: string, content: string, locale = "en") {
  const parts = chunkText(content);
  if (!parts.length) return;
  await fetch(`${URL}/rest/v1/kb_chunks`, {
    method: "POST",
    headers: { apikey: SRK, Authorization: `Bearer ${SRK}`, "Content-Type": "application/json", Prefer: "return=minimal" },
    body: JSON.stringify(parts.map((c, i) => ({ doc_id, chunk_index: i, content: c, locale }))),
  });
}

serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });
  if (req.headers.get("x-api-key") !== ADMIN_API_KEY) return new Response("forbidden", { status: 403 });

  const sources = [
    ...(await fetchASPS()),
    ...(await fetchBAAPS()),
    ...(await fetchOpenFDA()),
    ...(await fetchPubMed()),
  ];
  let inserted = 0;
  for (const s of sources) {
    const doc = normalize(s);
    if (!doc.title || !doc.source_url) continue;
    const id = await upsertDoc(doc);
    if (id) {
      inserted++;
      const content = `${doc.title}\n\n${doc.abstract ?? ""}`.trim();
      await insertChunks(id, content, doc.locale);
    }
  }
  return new Response(JSON.stringify({ inserted }), { headers: { "Content-Type": "application/json" } });
});


