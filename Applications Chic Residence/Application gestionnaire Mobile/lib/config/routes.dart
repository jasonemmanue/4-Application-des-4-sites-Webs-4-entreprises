import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../manage/bookings_screen.dart';
import '../manage/guests_screen.dart';
import '../manage/manager_home.dart';
import '../manage/residences_screen.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/task_detail/task_detail_screen.dart';
import '../screens/tasks/tasks_screen.dart';

NoTransitionPage<void> _tab(Widget child) => NoTransitionPage(child: child);

GoRouter buildRouter(WidgetRef ref) => GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final user = ref.read(currentUserProvider);
        final loc = state.matchedLocation;
        if (user == null) return loc == '/login' ? null : '/login';
        final manager = user.role == StaffRole.manager;
        // Chacun reste dans son espace : le gérant n'a pas les tâches de
        // nettoyage, l'agent n'a pas la gestion.
        if (loc == '/login') return manager ? '/m' : '/';
        if (manager && (loc == '/' || loc.startsWith('/tasks') || loc == '/stats')) {
          return '/m';
        }
        if (!manager && loc.startsWith('/m')) return '/';
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
            GoRoute(path: '/', pageBuilder: (_, __) => _tab(const DashboardScreen())),
            GoRoute(path: '/tasks', pageBuilder: (_, __) => _tab(const TasksScreen())),
            GoRoute(path: '/stats', pageBuilder: (_, __) => _tab(const StatsScreen())),
            GoRoute(path: '/profile', pageBuilder: (_, __) => _tab(const ProfileScreen())),
            GoRoute(path: '/m', pageBuilder: (_, __) => _tab(const ManagerHomeScreen())),
            GoRoute(
              path: '/m/residences',
              pageBuilder: (_, __) => _tab(const ResidencesScreen()),
            ),
            GoRoute(
              path: '/m/bookings',
              pageBuilder: (_, __) => _tab(const BookingsScreen()),
            ),
            GoRoute(
              path: '/m/guests',
              pageBuilder: (_, __) => _tab(const GuestsScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/tasks/:id',
          builder: (context, state) => TaskDetailScreen(
            taskId: state.pathParameters['id']!,
          ),
        ),
      ],
    );
