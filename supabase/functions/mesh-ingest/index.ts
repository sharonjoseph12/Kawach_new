// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface MeshIngestionPayload {
  msgId: string;
  type: "sos" | "location" | "ack";
  originUserId: string;
  payloadEncrypted: string; // base64
  ttl: number;
  timestamp: string; // ISO
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  // ── Auth ─────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const jwt = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Rate limit: 30 messages / device / hour ───────────────────────────
  const hourAgo = new Date(Date.now() - 3600_000).toISOString();
  const { count } = await supabase
    .from("mesh_messages")
    .select("id", { count: "exact", head: true })
    .eq("origin_user_id", user.id)
    .gte("created_at", hourAgo);

  if ((count ?? 0) >= 30) {
    return new Response(
      JSON.stringify({ error: "Rate limit exceeded. Max 30/hour." }),
      {
        status: 429,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // ── Parse body ────────────────────────────────────────────────────────
  let payload: MeshIngestionPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { msgId, type, originUserId, payloadEncrypted, ttl, timestamp } =
    payload;
  if (!msgId || !type || !originUserId || !payloadEncrypted) {
    return new Response(JSON.stringify({ error: "Missing required fields" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Deduplication ─────────────────────────────────────────────────────
  const { data: existing } = await supabase
    .from("mesh_messages")
    .select("id")
    .eq("msg_id", msgId)
    .maybeSingle();

  if (existing) {
    return new Response(
      JSON.stringify({ status: "duplicate", msgId }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // ── Insert mesh message ───────────────────────────────────────────────
  const { error: insertError } = await supabase.from("mesh_messages").insert({
    msg_id: msgId,
    type,
    origin_user_id: originUserId,
    payload_encrypted: payloadEncrypted,
    ttl,
    timestamp,
    created_at: new Date().toISOString(),
    synced_by: user.id,
  });

  if (insertError) {
    console.error("mesh_messages insert failed:", insertError);
    return new Response(JSON.stringify({ error: insertError.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Audit log ─────────────────────────────────────────────────────────
  await supabase.from("audit_log").insert({
    event: "mesh_message_received",
    actor_id: user.id,
    metadata: { msgId, type, originUserId },
    created_at: new Date().toISOString(),
  });

  // ── SOS processing ────────────────────────────────────────────────────
  if (type === "sos") {
    // For hackathon: treat the encrypted payload as base64 JSON
    // In production this would be decrypted with AES key from Vault
    let sosData: { userId: string; lat: number; lng: number; batteryPct: number };
    try {
      const decoded = atob(payloadEncrypted);
      sosData = JSON.parse(decoded);
    } catch {
      // Encrypted properly in prod; for now create a minimal SOS
      sosData = {
        userId: originUserId,
        lat: 0,
        lng: 0,
        batteryPct: -1,
      };
    }

    // Insert SOS alert
    const { data: sosAlert, error: sosError } = await supabase
      .from("sos_alerts")
      .insert({
        user_id: sosData.userId,
        lat: sosData.lat,
        lng: sosData.lng,
        battery_pct: sosData.batteryPct,
        trigger_type: "mesh_relay",
        status: "active",
        created_at: timestamp ?? new Date().toISOString(),
      })
      .select()
      .single();

    if (sosError || !sosAlert) {
      console.error("sos_alerts insert failed:", sosError);
      return new Response(
        JSON.stringify({ status: "stored", warning: "SOS insert failed" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Trigger guardian notifications
    await supabase.functions.invoke("notify-guardians", {
      body: {
        sosId: sosAlert.id,
        userId: sosData.userId,
        lat: sosData.lat,
        lng: sosData.lng,
        triggerType: "mesh_relay",
        batteryPct: sosData.batteryPct,
      },
    });

    return new Response(
      JSON.stringify({ status: "processed", sosId: sosAlert.id }),
      {
        status: 201,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  return new Response(
    JSON.stringify({ status: "stored", msgId }),
    {
      status: 201,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
});
