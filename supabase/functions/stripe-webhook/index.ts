import Stripe from "npm:stripe@17";
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  isStaleSubscriptionUpdate,
  isWebhookDuplicate,
  markWebhookProcessed,
} from "../_shared/webhook_idempotency.ts";

const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY");
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function mapStripeStatus(status: string): { plan: string; status: string } {
  switch (status) {
    case "trialing":
      return { plan: "pro", status: "trialing" };
    case "active":
      return { plan: "pro", status: "active" };
    case "canceled":
      return { plan: "free", status: "canceled" };
    case "unpaid":
    case "past_due":
    case "incomplete":
    case "incomplete_expired":
      return { plan: "free", status: "expired" };
    default:
      return { plan: "free", status: "expired" };
  }
}

async function loadExistingSubscription(
  supabase: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data, error } = await supabase
    .from("user_subscriptions")
    .select("expires_at, status, plan")
    .eq("user_id", userId)
    .maybeSingle();

  if (error) {
    console.error("subscription lookup error", error.message);
    throw error;
  }

  return data;
}

async function upsertSubscription(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  payload: Record<string, unknown>,
  expiresAt: string | null,
) {
  const existing = await loadExistingSubscription(supabase, userId);
  if (isStaleSubscriptionUpdate(existing, expiresAt)) {
    console.log(`Skipping stale subscription update for ${userId}`);
    return;
  }

  const { error } = await supabase.from("user_subscriptions").upsert({
    user_id: userId,
    ...payload,
  });
  if (error) {
    console.error("upsert error", error.message);
    throw error;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!stripeSecret || !webhookSecret || !supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Missing env configuration" }, 500);
  }

  const stripe = new Stripe(stripeSecret, { apiVersion: "2024-11-20.acacia" });
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return jsonResponse({ error: "Missing stripe-signature" }, 400);
  }

  const rawBody = await req.text();
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
  } catch (err) {
    console.error("Webhook signature verification failed", err);
    return jsonResponse({ error: "Invalid signature" }, 400);
  }

  if (await isWebhookDuplicate(supabase, event.id)) {
    return jsonResponse({ received: true, duplicate: true });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.client_reference_id;
        if (!userId) break;

        const subscriptionId = typeof session.subscription === "string"
          ? session.subscription
          : session.subscription?.id;

        let status = "active";
        let plan = "pro";
        let trialEndsAt: string | null = null;
        let expiresAt: string | null = null;

        if (subscriptionId) {
          const sub = await stripe.subscriptions.retrieve(subscriptionId);
          const mapped = mapStripeStatus(sub.status);
          plan = mapped.plan;
          status = mapped.status;
          if (sub.trial_end) {
            trialEndsAt = new Date(sub.trial_end * 1000).toISOString();
          }
          if (sub.current_period_end) {
            expiresAt = new Date(sub.current_period_end * 1000).toISOString();
          }
        }

        await upsertSubscription(supabase, userId, {
          plan,
          status,
          source: "stripe",
          external_id: subscriptionId ?? session.id,
          stripe_customer_id: typeof session.customer === "string"
            ? session.customer
            : session.customer?.id ?? null,
          stripe_subscription_id: subscriptionId ?? null,
          trial_ends_at: trialEndsAt,
          expires_at: expiresAt,
        }, expiresAt);
        break;
      }

      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const userId = sub.metadata?.supabase_user_id;
        const mapped = mapStripeStatus(sub.status);
        const trialEndsAt = sub.trial_end
          ? new Date(sub.trial_end * 1000).toISOString()
          : null;
        const expiresAt = sub.current_period_end
          ? new Date(sub.current_period_end * 1000).toISOString()
          : null;

        const payload = {
          plan: mapped.plan,
          status: mapped.status,
          source: "stripe",
          external_id: sub.id,
          stripe_customer_id: typeof sub.customer === "string"
            ? sub.customer
            : sub.customer?.id ?? null,
          stripe_subscription_id: sub.id,
          trial_ends_at: trialEndsAt,
          expires_at: expiresAt,
        };

        if (userId) {
          await upsertSubscription(supabase, userId, payload, expiresAt);
          break;
        }

        const customerId = typeof sub.customer === "string"
          ? sub.customer
          : sub.customer?.id;
        if (customerId) {
          const { data: row } = await supabase
            .from("user_subscriptions")
            .select("user_id")
            .eq("stripe_customer_id", customerId)
            .maybeSingle();

          if (row?.user_id) {
            await upsertSubscription(supabase, row.user_id, payload, expiresAt);
          }
        }
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    await markWebhookProcessed(supabase, event.id, "stripe");
    return jsonResponse({ received: true });
  } catch (err) {
    console.error("Webhook handler error", err);
    return jsonResponse({ error: "Webhook handler failed" }, 500);
  }
});
