import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/admin/bookings_screen.dart';
import '../screens/admin/contacts_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/more_screen.dart';
import '../screens/admin/payments_screen.dart';
import '../screens/admin/residences_screen.dart';
import '../screens/admin/reviews_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/field/cleaning_screen.dart';
import '../screens/field/performance_screen.dart';
import '../screens/field/staff_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/main_scaffold.dart';

NoTransitionPage<void> _tab(Widget child) => NoTransitionPage(child: child);

GoRouter buildRouter(WidgetRef ref) => GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final admin = ref.read(currentAdminProvider);
        final onLogin = state.matchedLocation == '/login';
        if (admin == null && !onLogin) return '/login';
        if (admin != null && onLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              MainShell(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (_, __) => _tab(const DashboardScreen()),
            ),
            GoRoute(
              path: '/residences',
              pageBuilder: (_, __) => _tab(const ResidencesScreen()),
            ),
            GoRoute(
              path: '/bookings',
              pageBuilder: (_, __) => _tab(const BookingsScreen()),
            ),
            GoRoute(
              path: '/cleaning',
              pageBuilder: (_, __) => _tab(const CleaningScreen()),
            ),
            GoRoute(
              path: '/more',
              pageBuilder: (_, __) => _tab(const MoreScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/payments',
          builder: (_, __) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/reviews',
          builder: (_, __) => const ReviewsScreen(),
        ),
        GoRoute(
          path: '/contacts',
          builder: (_, __) => const ContactsScreen(),
        ),
        GoRoute(
          path: '/staff',
          builder: (_, __) => const StaffScreen(),
        ),
        GoRoute(
          path: '/performance',
          builder: (_, __) => const PerformanceScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    );
