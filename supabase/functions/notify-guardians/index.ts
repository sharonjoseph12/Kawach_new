// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface NotifyPayload {
  sosId: string;
  userId: string;
  lat: number;
  lng: number;
  triggerType: string;
  batteryPct: number;
}

async function sendFcmPush(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const fcmKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmKey) return false;

  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${fcmKey}`,
    },
    body: JSON.stringify({
      to: fcmToken,
      notification: { title, body, sound: "default" },
      data,
      priority: "high",
      time_to_live: 300,
    }),
  });
  return res.ok;
}

async function sendTwilioSms(
  to: string,
  message: string
): Promise<boolean> {
  const sid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const token = Deno.env.get("TWILIO_AUTH_TOKEN");
  const from = Deno.env.get("TWILIO_PHONE_NUMBER");
  if (!sid || !token || !from) return false;

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${sid}:${token}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({ To: to, From: from, Body: message }),
    }
  );
  return res.ok;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  let payload: NotifyPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { sosId, userId, lat, lng, triggerType, batteryPct } = payload;

  // 1. Fetch user name
  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name")
    .eq("id", userId)
    .maybeSingle();
  const userName = profile?.full_name ?? "Kawach User";

  // 2. Fetch guardians
  const { data: guardians } = await supabase
    .from("guardians")
    .select("id, name, phone, guardian_user_id")
    .eq("user_id", userId);

  if (!guardians || guardians.length === 0) {
    return new Response(
      JSON.stringify({ notified: 0, failed: 0, warning: "No guardians" }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // 3. Fetch FCM tokens for guardian user accounts
  const guardianUserIds = guardians
    .map((g: any) => g.guardian_user_id)
    .filter(Boolean);

  const { data: deviceTokens } = await supabase
    .from("device_tokens")
    .select("user_id, token")
    .in("user_id", guardianUserIds);

  const tokenByUserId: Record<string, string> = {};
  for (const t of deviceTokens ?? []) {
    tokenByUserId[t.user_id] = t.token;
  }

  // 4. Notify each guardian
  let notified = 0;
  let failed = 0;
  const mapsLink = `https://maps.google.com/?q=${lat},${lng}`;
  const pushTitle = `⚠️ SOS ALERT — ${userName}`;
  const pushBody = `Emergency triggered. Tap to track location.`;
  const smsBody = `KAWACH SOS: ${userName} needs help.\nLocation: ${mapsLink}\nReply SAFE to cancel.`;
  const pushData: Record<string, string> = {
    sosId,
    lat: String(lat),
    lng: String(lng),
    userId,
    triggerType,
    batteryPct: String(batteryPct),
  };

  for (const guardian of guardians) {
    let success = false;

    const fcmToken = guardian.guardian_user_id
      ? tokenByUserId[guardian.guardian_user_id]
      : null;

    if (fcmToken) {
      success = await sendFcmPush(fcmToken, pushTitle, pushBody, pushData);
    } else if (guardian.phone) {
      success = await sendTwilioSms(guardian.phone, smsBody);
    }

    if (success) {
      notified++;
    } else {
      failed++;
    }

    // 5. Audit log per guardian
    await supabase.from("audit_log").insert({
      event: "guardian_notification_sent",
      actor_id: userId,
      metadata: {
        sosId,
        guardianId: guardian.id,
        method: fcmToken ? "fcm" : "sms",
        success,
      },
      created_at: new Date().toISOString(),
    });
  }

  if (notified === 0 && failed > 0) {
    return new Response(
      JSON.stringify({
        error: "All guardian notifications failed",
        notified,
        failed,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  return new Response(
    JSON.stringify({ notified, failed }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
});
