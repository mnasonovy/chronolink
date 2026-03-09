import 'package:go_router/go_router.dart';

import '../presentation/screens/day_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/month_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/week_screen.dart';

abstract final class AppRoute {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String month = '/month';
  static const String week = '/week';
  static const String day = '/day';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoute.onboarding,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoute.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoute.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoute.month,
      name: 'month',
      builder: (context, state) => const MonthScreen(),
    ),
    GoRoute(
      path: AppRoute.week,
      name: 'week',
      builder: (context, state) => const WeekScreen(),
    ),
    GoRoute(
      path: AppRoute.day,
      name: 'day',
      builder: (context, state) => const DayScreen(),
    ),
  ],
);