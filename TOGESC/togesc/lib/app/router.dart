import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/game_constants.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/speed_game_screen.dart';
import '../screens/speed_mode_select_screen.dart';
import '../screens/statistics_screen.dart';
import '../services/app_preferences.dart';

/// Rutas de la aplicacion.
abstract final class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const statistics = '/statistics';
  static const speedSelect = '/speed';
  static const game = '/game';
  static const speedGame = '/speed/game';
}

GoRouter createAppRouter({required Listenable refreshListenable}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(onboardingCompleteKey) ?? false;
      final location = state.matchedLocation;

      if (!done && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (done && location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (_, _) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.speedSelect,
        builder: (_, _) => const SpeedModeSelectScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.game}/:modeId',
        builder: (context, state) {
          final modeId = int.parse(state.pathParameters['modeId']!);
          final mode = GameMode.fromId(modeId);
          if (mode == null || mode == GameMode.exit) {
            return const HomeScreen();
          }
          return GameScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '${AppRoutes.speedGame}/:modeId',
        builder: (context, state) {
          final modeId = int.parse(state.pathParameters['modeId']!);
          final mode = GameMode.fromId(modeId);
          if (mode == null) {
            return const SpeedModeSelectScreen();
          }
          return SpeedGameScreen(targetMode: mode);
        },
      ),
    ],
  );
}
