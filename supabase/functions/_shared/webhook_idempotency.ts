import { SupabaseClient } from "npm:@supabase/supabase-js@2";

export type WebhookSource = "stripe" | "revenuecat";

export async function isWebhookDuplicate(
  supabase: SupabaseClient,
  eventId: string,
): Promise<boolean> {
  const { data, error } = await supabase
    .from("processed_webhook_events")
    .select("event_id")
    .eq("event_id", eventId)
    .maybeSingle();

  if (error) {
    console.error("idempotency lookup error", error.message);
    throw error;
  }

  return data != null;
}

export async function markWebhookProcessed(
  supabase: SupabaseClient,
  eventId: string,
  source: WebhookSource,
): Promise<void> {
  const { error } = await supabase.from("processed_webhook_events").insert({
    event_id: eventId,
    source,
  });

  if (error?.code === "23505") return;

  if (error) {
    console.error("idempotency insert error", error.message);
    throw error;
  }
}

type SubscriptionRow = {
  expires_at: string | null;
  status: string;
  plan: string;
};

/** Evita aplicar un evento de suscripcion mas antiguo que el estado almacenado. */
export function isStaleSubscriptionUpdate(
  existing: SubscriptionRow | null,
  incomingExpiresAt: string | null,
): boolean {
  if (!existing?.expires_at || !incomingExpiresAt) return false;

  const existingMs = new Date(existing.expires_at).getTime();
  const incomingMs = new Date(incomingExpiresAt).getTime();

  return incomingMs < existingMs;
}
