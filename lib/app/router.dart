import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/day_screen.dart';
import '../presentation/screens/month_screen.dart';
import '../presentation/screens/week_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/month',
  routes: <RouteBase>[
    GoRoute(
      path: '/month',
      builder: (BuildContext context, GoRouterState state) => const MonthScreen(),
    ),
    GoRoute(
      path: '/week',
      builder: (BuildContext context, GoRouterState state) => const WeekScreen(),
    ),
    GoRoute(
      path: '/day',
      builder: (BuildContext context, GoRouterState state) => const DayScreen(),
    ),
  ],
);
