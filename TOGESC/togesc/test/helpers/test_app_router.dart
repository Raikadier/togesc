import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/widgets/togesc_shell.dart';

/// Router minimo para widget/e2e tests (sin redirect de onboarding).
GoRouter buildTestRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.speedSelect,
        builder: (_, _) => const SpeedModeSelectScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.game}/:modeId',
        builder: (_, state) {
          final mode = GameMode.fromId(
            int.parse(state.pathParameters['modeId']!),
          )!;
          return GameScreen(mode: mode);
        },
      ),
      ShellRoute(
        builder: (_, _, child) => TogescShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: AppRoutes.statistics,
            builder: (_, _) => const StatisticsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Marca onboarding como completado en tests.
void markOnboardingCompleteForTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    onboardingCompleteKey: true,
  });
}
