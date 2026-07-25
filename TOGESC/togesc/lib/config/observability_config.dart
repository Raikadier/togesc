/// Config observabilidad (Fase 6) via --dart-define.
abstract final class ObservabilityConfig {
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );
  static const analyticsEnabled = bool.fromEnvironment(
    'ANALYTICS_ENABLED',
    defaultValue: true,
  );

  static bool get isSentryConfigured => sentryDsn.isNotEmpty;
}
