import { createClient } from "npm:@supabase/supabase-js@2";

const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

type RcEvent = {
  type?: string;
  app_user_id?: string;
  product_id?: string;
  expiration_at_ms?: number | null;
  period_type?: string;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!webhookSecret || !supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Missing env configuration" }, 500);
  }

  const authHeader = req.headers.get("authorization");
  if (authHeader !== `Bearer ${webhookSecret}`) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const body = await req.json();
  const event: RcEvent = body.event ?? body;
  const userId = event.app_user_id;

  if (!userId) {
    return jsonResponse({ received: true, skipped: "no app_user_id" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const eventType = event.type ?? "";

  const activeEvents = new Set([
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "PRODUCT_CHANGE",
    "SUBSCRIPTION_EXTENDED",
  ]);

  const inactiveEvents = new Set([
    "CANCELLATION",
    "EXPIRATION",
    "BILLING_ISSUE",
  ]);

  let plan = "free";
  let status = "expired";
  let trialEndsAt: string | null = null;
  let expiresAt: string | null = null;

  if (activeEvents.has(eventType)) {
    plan = "pro";
    status = event.period_type === "trial" ? "trialing" : "active";
  } else if (!inactiveEvents.has(eventType)) {
    return jsonResponse({ received: true, skipped: eventType });
  }

  if (event.expiration_at_ms) {
    const exp = new Date(event.expiration_at_ms);
    expiresAt = exp.toISOString();
    if (status === "trialing") {
      trialEndsAt = exp.toISOString();
    }
    if (exp.getTime() < Date.now() && inactiveEvents.has(eventType)) {
      plan = "free";
      status = "expired";
    }
  }

  const { error } = await supabase.from("user_subscriptions").upsert({
    user_id: userId,
    plan,
    status,
    source: "revenuecat",
    external_id: event.product_id ?? null,
    trial_ends_at: trialEndsAt,
    expires_at: expiresAt,
  });

  if (error) {
    console.error("RevenueCat upsert error", error);
    return jsonResponse({ error: "Upsert failed" }, 500);
  }

  return jsonResponse({ received: true });
});
