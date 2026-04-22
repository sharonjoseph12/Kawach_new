// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Simple geohash encoder (base32, precision 5 = ~5km²)
const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";
function encodeGeohash(lat: number, lng: number, precision = 5): string {
  let idx = 0, bit = 0, evenBit = true, geohash = "";
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  while (geohash.length < precision) {
    if (evenBit) {
      const lngMid = (lngMin + lngMax) / 2;
      if (lng >= lngMid) { idx = idx * 2 + 1; lngMin = lngMid; }
      else { idx = idx * 2; lngMax = lngMid; }
    } else {
      const latMid = (latMin + latMax) / 2;
      if (lat >= latMid) { idx = idx * 2 + 1; latMin = latMid; }
      else { idx = idx * 2; latMax = latMid; }
    }
    evenBit = !evenBit;
    if (++bit === 5) {
      geohash += BASE32[idx];
      bit = 0; idx = 0;
    }
  }
  return geohash;
}

function daysSince(dateStr: string): number {
  return (Date.now() - new Date(dateStr).getTime()) / 86_400_000;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function computeScores(supabase: any): Promise<void> {
  const ninetyDaysAgo = new Date(
    Date.now() - 90 * 86_400_000
  ).toISOString();

  const { data: reports, error } = await supabase
    .from("community_reports")
    .select("lat, lng, severity, reported_at")
    .gte("reported_at", ninetyDaysAgo);

  if (error) throw new Error(`Fetch reports failed: ${error.message}`);
  if (!reports || reports.length === 0) {
    console.log("No reports to process.");
    return;
  }

  // Group by geohash-5
  const grouped: Record<
    string,
    { lat: number; lng: number; reports: any[] }
  > = {};

  for (const r of reports) {
    const gh = encodeGeohash(r.lat, r.lng, 5);
    if (!grouped[gh]) {
      grouped[gh] = { lat: r.lat, lng: r.lng, reports: [] };
    }
    grouped[gh].reports.push(r);
  }

  let processed = 0;
  for (const [geohash, { lat, lng, reports: rpts }] of Object.entries(
    grouped
  )) {
    let score = 100;
    for (const r of rpts) {
      const age = daysSince(r.reported_at);
      const weight = age < 7 ? 2.0 : age < 30 ? 1.5 : 1.0;
      const severity = Number(r.severity) || 1;
      score -= severity * 6 * weight;
    }
    score = Math.max(0, Math.min(100, Math.round(score)));
    const label: "safe" | "moderate" | "dangerous" =
      score > 70 ? "safe" : score > 40 ? "moderate" : "dangerous";

    const { error: upsertError } = await supabase
      .from("safety_scores")
      .upsert(
        {
          geohash,
          lat,
          lng,
          score,
          incident_count: rpts.length,
          label,
          computed_at: new Date().toISOString(),
        },
        { onConflict: "geohash" }
      );

    if (upsertError) {
      console.error(`Upsert failed for ${geohash}:`, upsertError.message);
    } else {
      processed++;
    }
  }

  console.log(
    `Processed ${processed}/${Object.keys(grouped).length} geohash tiles.`
  );
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  try {
    await computeScores(supabase);
    return new Response(
      JSON.stringify({ success: true, message: "Safety scores computed." }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e: any) {
    console.error("compute-safety-scores error:", e);
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
