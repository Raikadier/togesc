/// Estado de suscripcion del usuario (cache Supabase + tiendas).
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.plan,
    required this.status,
    this.trialEndsAt,
    this.expiresAt,
    this.source,
  });

  const SubscriptionStatus.free()
      : plan = 'free',
        status = 'active',
        trialEndsAt = null,
        expiresAt = null,
        source = null;

  final String plan;
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? expiresAt;
  final String? source;

  bool get isPro {
    if (plan != 'pro') return false;
    if (status == 'active' || status == 'trialing') {
      if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
        return false;
      }
      return true;
    }
    return false;
  }

  bool get isTrialing =>
      status == 'trialing' &&
      (trialEndsAt == null || trialEndsAt!.isAfter(DateTime.now()));

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return SubscriptionStatus(
      plan: json['plan'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      trialEndsAt: parseDate(json['trial_ends_at'] as String?),
      expiresAt: parseDate(json['expires_at'] as String?),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'status': status,
        if (trialEndsAt != null) 'trial_ends_at': trialEndsAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (source != null) 'source': source,
      };
}
