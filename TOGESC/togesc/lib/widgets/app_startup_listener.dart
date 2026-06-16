import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../providers/analytics_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/sync_provider.dart';
import '../services/app_preferences.dart';

/// Arranque: analytics app_open, contador de sesion y sync inicial si hay sesion.
class AppStartupListener extends ConsumerStatefulWidget {
  const AppStartupListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppStartupListener> createState() =>
      _AppStartupListenerState();
}

class _AppStartupListenerState extends ConsumerState<AppStartupListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStartup());
  }

  Future<void> _onStartup() async {
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.incrementSessionCount();
    await ref.read(trackAppOpenProvider)();
    if (SupabaseConfig.isConfigured) {
      await ref.read(syncNowProvider)();
      ref.invalidate(srsSystemProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
