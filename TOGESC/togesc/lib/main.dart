import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_theme.dart';
import 'config/observability_config.dart';
import 'config/supabase_config.dart';
import 'providers/router_provider.dart';
import 'widgets/app_startup_listener.dart';
import 'widgets/auth_sync_listener.dart';
import 'widgets/csat_survey_listener.dart';
import 'widgets/subscription_checkout_listener.dart';

Future<void> main() async {
  if (ObservabilityConfig.isSentryConfigured) {
    await SentryFlutter.init(
      (options) {
        options.dsn = ObservabilityConfig.sentryDsn;
        options.environment = 'production';
        options.release = 'togesc@1.0.0';
        options.tracesSampleRate = 0.2;
      },
      appRunner: _bootstrap,
    );
  } else {
    await _bootstrap();
  }
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  runApp(
    const ProviderScope(
      child: AppStartupListener(
        child: CsatSurveyListener(
          child: SubscriptionCheckoutListener(
            child: AuthSyncListener(child: TogescApp()),
          ),
        ),
      ),
    ),
  );
}

class TogescApp extends ConsumerWidget {
  const TogescApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Entrenador de Oido Absoluto',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
