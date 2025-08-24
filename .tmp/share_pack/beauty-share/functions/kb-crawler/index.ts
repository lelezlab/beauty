import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { DOMParser, Element } from "https://deno.land/x/deno_dom@v0.1.45/deno-dom-wasm.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ADMIN_API_KEY = Deno.env.get("ADMIN_API_KEY") || "";
const OPENFDA_API_KEY = Deno.env.get("OPENFDA_API_KEY") || "";
const PUBMED_EMAIL = Deno.env.get("PUBMED_EMAIL") || "dev@example.com";
const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function iso(d?: string|null){ return d? new Date(d).toISOString(): null; }
function chunk(txt: string, size=800){ const w=txt.split(/\s+/); const out:string[]=[]; let buf:string[]=[]; for(const t of w){ buf.push(t); if(buf.join(" ").length>=size){ out.push(buf.join(" ")); buf=[]; } } if(buf.length) out.push(buf.join(" ")); return out; }
async function upsertDoc(doc:any){ const {data,error}=await sb.from("kb_docs").upsert(doc,{onConflict:"source_url"}).select("id"); if(error) throw error; return data?.[0]?.id as number; }
async function writeChunks(id:number, locale:string, text:string, url:string){ const rows=chunk(text).map(c=>({doc_id:id, locale, chunk:c, source_url:url})); if(!rows.length) return; const {error}=await sb.from("kb_chunks").insert(rows); if(error) throw error; }

async function fetchASPS(){ let cnt=0; const res=await fetch("https://www.plasticsurgery.org/news"); if(!res.ok) return 0; const html=await res.text(); const doc=new DOMParser().parseFromString(html,"text/html"); if(!doc) return 0;
  for(const a of doc.querySelectorAll("article")){ const el=a as Element; const at=el.querySelector("a"); const title=at?.textContent?.trim()||"ASPS News"; const href=at?.getAttribute("href")||""; if(!href) continue; const link=href.startsWith("http")?href:"https://www.plasticsurgery.org"+href; const sn=el.querySelector("p")?.textContent?.trim()||""; const tm=el.querySelector("time")?.getAttribute("datetime")||null;
    const id=await upsertDoc({source:"ASPS", title, snippet:sn, tags:["surgery"], jurisdiction:"US", evidence_level:"news", published_at:iso(tm), source_url:link, raw:{list:"/news"}}); if(id) cnt++; }
  return cnt; }

async function fetchBAAPS(){ let cnt=0; const res=await fetch("https://baaps.org.uk/media/press-releases"); if(!res.ok) return 0; const html=await res.text(); const doc=new DOMParser().parseFromString(html,"text/html"); if(!doc) return 0;
  for(const li of doc.querySelectorAll("li")){ const el=li as Element; const at=el.querySelector("a"); const title=at?.textContent?.trim()||"BAAPS"; const href=at?.getAttribute("href")||""; if(!href) continue; const link=href.startsWith("http")?href:"https://baaps.org.uk"+href;
    const id=await upsertDoc({source:"BAAPS", title, snippet:el.textContent?.trim().slice(0,300)||"", tags:["uk"], jurisdiction:"UK", evidence_level:"news", published_at:null, source_url:link, raw:{list:"/press-releases"}}); if(id) cnt++; }
  return cnt; }

async function fetchOpenFDA510k(){ let cnt=0; const d=new Date(Date.now()-30*24*3600*1000).toISOString().slice(0,10); const url=`https://api.fda.gov/device/510k.json?search=decision_date:[${d}+TO+*]&limit=50${OPENFDA_API_KEY?`&api_key=${OPENFDA_API_KEY}`:""}`;
  const r=await fetch(url); if(!r.ok) return 0; const j=await r.json().catch(()=>({})); const arr=j.results||[]; for(const it of arr){ const id=await upsertDoc({source:"openFDA510k", title:`${it.device_name||"Device"} 510(k)`, snippet: it.decision_description||"", tags:[it.product_code||"device"], jurisdiction:"US", evidence_level:"regulatory", published_at: iso(it.decision_date), source_url:`https://api.fda.gov/device/510k.json?knumber=${it.k_number||""}`, raw: it}); if(id) cnt++; } return cnt; }

async function fetchOpenFDARecall(){ let cnt=0; const d=new Date(Date.now()-30*24*3600*1000).toISOString().slice(0,10); const url=`https://api.fda.gov/device/recall.json?search=report_date:[${d}+TO+*]&limit=50${OPENFDA_API_KEY?`&api_key=${OPENFDA_API_KEY}`:""}`;
  const r=await fetch(url); if(!r.ok) return 0; const j=await r.json().catch(()=>({})); const arr=j.results||[]; for(const it of arr){ const id=await upsertDoc({source:"openFDArecall", title: it.recalling_firm?`Recall: ${it.recalling_firm}`:"Device Recall", snippet: it.reason_for_recall||"", tags:[it.product_code||"device","recall"], jurisdiction:"US", evidence_level:"regulatory", published_at: iso(it.report_date), source_url:"https://api.fda.gov/device/recall.json", raw: it}); if(id) cnt++; } return cnt; }

async function fetchPubMed(){ let cnt=0; const terms=["rhinoplasty","blepharoplasty","botulinum toxin","dermal filler","laser resurfacing","RF microneedling","HIFU skin tightening","jawline contouring","chin augmentation"];
  for(const term of terms){ const q=`https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=${encodeURIComponent(term)}&retmax=5&reldate=30&usehistory=y&email=${encodeURIComponent(PUBMED_EMAIL)}&retmode=json`;
    const r=await fetch(q); if(!r.ok) continue; const j=await r.json().catch(()=>({})); const ids=j.esearchresult?.idlist||[]; if(!ids.length) continue;
    const fx=await fetch(`https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=${ids.join(",")}&retmode=xml`); if(!fx.ok) continue; const xml=await fx.text(); const sn=xml.slice(0,1500);
    const id=await upsertDoc({source:"PubMed", title:`PubMed: ${term}`, snippet:`Latest for ${term}`, tags:[term.replace(/\s+/g,"_"),"paper"], jurisdiction:"Global", evidence_level:"paper", published_at: new Date().toISOString(), source_url:`https://pubmed.ncbi.nlm.nih.gov/?term=${encodeURIComponent(term)}`, raw:{ids,xml_sample:sn}});
    if(id) { await writeChunks(id, "en-US", sn, `https://pubmed.ncbi.nlm.nih.gov/?term=${encodeURIComponent(term)}`); cnt++; }
  } return cnt; }

async function runAll(){ return {
  ASPS: await fetchASPS().catch(()=>-1),
  BAAPS: await fetchBAAPS().catch(()=>-1),
  openFDA510k: await fetchOpenFDA510k().catch(()=>-1),
  openFDArecall: await fetchOpenFDARecall().catch(()=>-1),
  PubMed: await fetchPubMed().catch(()=>-1),
};}

serve(async (req)=>{
  const url=new URL(req.url);
  if(req.method==="GET" && url.pathname==="/ping") return new Response(JSON.stringify({ok:true,time:new Date().toISOString()}),{headers:{"Content-Type":"application/json"}});
  if(req.method==="POST" && url.pathname==="/run"){
    if(!ADMIN_API_KEY || req.headers.get("x-api-key")!==ADMIN_API_KEY) return new Response("Forbidden",{status:403});
    const out=await runAll(); return new Response(JSON.stringify(out,null,2),{headers:{"Content-Type":"application/json"}});
  }
  return new Response("Not found",{status:404});
});
