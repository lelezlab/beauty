import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ADMIN_API_KEY = Deno.env.get("ADMIN_API_KEY") || "";
const PRIVATE_KEY_PEM = Deno.env.get("MANIFEST_SIGNING_PRIVATE_PEM") || "";
const PUBLIC_KEY_PEM = Deno.env.get("MANIFEST_SIGNING_PUBLIC_PEM") || "";
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const raw = atob(b64); const arr = new Uint8Array(raw.length);
  for (let i=0;i<raw.length;i++) arr[i]=raw.charCodeAt(i);
  return arr.buffer;
}
async function importPrivateKey(pem: string) {
  return await crypto.subtle.importKey("pkcs8", pemToArrayBuffer(pem), { name:"ECDSA", namedCurve:"P-256" }, false, ["sign"]);
}
function stableStringify(obj: any): string {
  if (Array.isArray(obj)) return "["+obj.map(stableStringify).join(",")+"]";
  if (obj && typeof obj==="object") return "{"+Object.keys(obj).sort().map(k=>JSON.stringify(k)+":"+stableStringify(obj[k])).join(",")+"}";
  return JSON.stringify(obj);
}
function b64(ab: ArrayBuffer){const u=new Uint8Array(ab);let s="";for(const c of u)s+=String.fromCharCode(c);return btoa(s);}

serve(async (req) => {
  const url = new URL(req.url);
  if (req.method==="GET" && url.pathname==="/latest") {
    const { data, error } = await supabase.from("effect_manifest").select("*").order("created_at",{ascending:false}).limit(1).single();
    if (error) return new Response(error.message,{status:500});
    return new Response(JSON.stringify(data),{headers:{"Content-Type":"application/json"}});
  }
  if (req.method==="GET" && url.pathname==="/pubkey") {
    return new Response(JSON.stringify({ public_pem: PUBLIC_KEY_PEM }), { headers: {"Content-Type":"application/json"} });
  }
  if (req.method==="POST" && url.pathname==="/") {
    if (!ADMIN_API_KEY || req.headers.get("x-api-key") !== ADMIN_API_KEY) return new Response("Forbidden",{status:403});
    const json = await req.json().catch(()=>({})); delete (json as any).signature;
    const payload = new TextEncoder().encode(stableStringify(json));
    const key = await importPrivateKey(PRIVATE_KEY_PEM);
    const sig = await crypto.subtle.sign({name:"ECDSA", hash:"SHA-256"}, key, payload);
    const created_at = new Date().toISOString();
    const { error } = await supabase.from("effect_manifest").insert({ version: (json as any).version ?? 1, json, signature: b64(sig), created_at });
    if (error) return new Response(error.message,{status:500});
    return new Response(JSON.stringify({ json, signature: b64(sig), payload_b64: b64(payload.buffer), created_at }), { headers: {"Content-Type":"application/json"} });
  }
  return new Response("Not found",{status:404});
});
