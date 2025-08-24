// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const PROJECT_URL = Deno.env.get("SUPABASE_URL")!;
const HMAC_SECRET = Deno.env.get("INGEST_HMAC_KEY") ?? "";

function verifySignature(raw: string, sig: string) {
  if (!HMAC_SECRET) return true; // disabled
  const encoder = new TextEncoder();
  const keyData = encoder.encode(HMAC_SECRET);
  const msgData = encoder.encode(raw);
  const cryptoKey = crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
  return cryptoKey.then((key) => crypto.subtle.sign("HMAC", key, msgData)).then((buf) => {
    const b64 = btoa(String.fromCharCode(...new Uint8Array(buf)));
    return b64 === sig;
  });
}

async function insert(table: string, rows: any[]) {
  const resp = await fetch(`${PROJECT_URL}/rest/v1/${table}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      Prefer: "return=minimal",
    },
    body: JSON.stringify(rows),
  });
  if (!resp.ok) throw new Error(`Insert ${table} failed: ${resp.status}`);
}

serve(async (req) => {
  const sig = req.headers.get("x-signature") ?? "";
  const raw = await req.text();
  const ok = await verifySignature(raw, sig);
  if (!ok) return new Response("bad signature", { status: 401 });
  const lines = raw.split("\n").filter(Boolean);
  for (const line of lines) {
    const evt = JSON.parse(line);
    switch (evt.kind) {
      case "capture":
        await insert("captures", [{
          session_id: evt.session.sessionId,
          view: "front",
          qc_json: evt.captureQC ?? null,
        }]);
        break;
      case "geometry":
        await insert("captures", [{
          session_id: evt.session.sessionId,
          view: "front",
          meta_json: { geom: evt.geom, metrics: evt.metrics ?? null },
        }]);
        break;
      case "effect":
        await insert("effects", [{
          session_id: evt.session.sessionId,
          effect_id: evt.effect.effectId,
          version: evt.effect.version,
          params_json: evt.effect.params,
          confidence: evt.effect.confidenceScore ?? null,
        }]);
        break;
      case "rating":
        await insert("ratings", [{
          session_id: evt.session.sessionId,
          realism: evt.rating.realism ?? null,
          satisfaction: evt.rating.satisfaction ?? null,
          regions: evt.rating.regions ?? null,
        }]);
        break;
      case "expert":
        await insert("experts", [{
          session_id: evt.session.sessionId,
          clinic_id: "edge",
          advice_json: evt.expert ?? null,
        }]);
        break;
      default:
        // ignore
        break;
    }
  }
  return new Response("ok");
});


