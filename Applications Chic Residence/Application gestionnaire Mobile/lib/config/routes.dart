import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/task_detail/task_detail_screen.dart';
import '../screens/tasks/tasks_screen.dart';

GoRouter buildRouter(WidgetRef ref) => GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final user = ref.read(currentUserProvider);
        final onLogin = state.matchedLocation == '/login';
        if (user == null && !onLogin) return '/login';
        if (user != null && onLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(
            location: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TasksScreen()),
            ),
            GoRoute(
              path: '/stats',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: StatsScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/tasks/:id',
          builder: (context, state) => TaskDetailScreen(
            taskId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    );
