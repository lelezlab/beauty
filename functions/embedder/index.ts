import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || "";
const MODEL = Deno.env.get("MODEL_EMBED") || "text-embedding-3-small";
const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function nextBatch(limit=50){
  const { data, error } = await sb.from("kb_chunks").select("id,chunk").is("embedding", null).limit(limit);
  if (error) throw error; return data ?? [];
}
async function embed(texts:string[]): Promise<number[][]>{
  const r = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST", headers: {"Authorization":`Bearer ${OPENAI_API_KEY}","Content-Type":"application/json"},
    body: JSON.stringify({ input: texts, model: MODEL })
  });
  if(!r.ok){ throw new Error(await r.text()); }
  const j = await r.json(); return j.data.map((d:any)=>d.embedding);
}
serve(async (req)=>{
  if(req.method!=="POST") return new Response("Only POST",{status:405});
  const body = await req.json().catch(()=>({})); const limit = typeof body.limit==="number"? body.limit : 50;
  const rows = await nextBatch(limit); if(!rows.length) return new Response(JSON.stringify({done:true,updated:0}),{headers:{"Content-Type":"application/json"}});
  const vecs = await embed(rows.map((r:any)=>r.chunk));
  const updates = rows.map((r:any,i:number)=>({ id:r.id, embedding: vecs[i] }));
  const { error } = await sb.from("kb_chunks").upsert(updates); if(error) return new Response(error.message,{status:500});
  return new Response(JSON.stringify({done:false,updated:updates.length}),{headers:{"Content-Type":"application/json"}});
});
