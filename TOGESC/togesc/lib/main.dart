import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_theme.dart';
import 'providers/audio_provider.dart';
import 'providers/router_provider.dart';

void main() {
  runApp(const ProviderScope(child: TogescApp()));
}

class TogescApp extends ConsumerStatefulWidget {
  const TogescApp({super.key});

  @override
  ConsumerState<TogescApp> createState() => _TogescAppState();
}

class _TogescAppState extends ConsumerState<TogescApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
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
