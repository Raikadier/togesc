import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/game_constants.dart';
import '../screens/about_screen.dart';
import '../screens/account_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/speed_game_screen.dart';
import '../screens/speed_mode_select_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/subscription_screen.dart';
import '../services/app_preferences.dart';
import '../widgets/pro_route_guard.dart';

/// Rutas de la aplicacion.
abstract final class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const statistics = '/statistics';
  static const about = '/about';
  static const privacy = '/privacy';
  static const account = '/account';
  static const subscription = '/subscription';
  static const paywall = '/paywall';
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
        path: AppRoutes.about,
        builder: (_, _) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) {
          final feature = state.uri.queryParameters['feature'];
          return PaywallScreen(feature: feature);
        },
      ),
      GoRoute(
        path: AppRoutes.speedSelect,
        builder: (_, _) => ProRouteGuard(
          mode: GameMode.speedTraining,
          child: const SpeedModeSelectScreen(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.game}/:modeId',
        builder: (context, state) {
          final modeId = int.parse(state.pathParameters['modeId']!);
          final mode = GameMode.fromId(modeId);
          if (mode == null || mode == GameMode.exit) {
            return const HomeScreen();
          }
          return ProRouteGuard(
            mode: mode,
            child: GameScreen(mode: mode),
          );
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
          return ProRouteGuard(
            mode: GameMode.speedTraining,
            child: SpeedGameScreen(targetMode: mode),
          );
        },
      ),
    ],
  );
}
