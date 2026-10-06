import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/cleaning/cleaning_overview_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/performance/performance_screen.dart';
import '../screens/placeholder_screens.dart';
import '../screens/staff/staff_screen.dart';

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
        GoRoute(
          path: '/',
          builder: (context, state) => MainScaffold(
            title: 'Dashboard',
            location: state.matchedLocation,
            body: const DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/residences',
          builder: (context, state) => MainScaffold(
            title: 'Residences',
            location: state.matchedLocation,
            body: const ResidencesScreen(),
          ),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => MainScaffold(
            title: 'Reservations',
            location: state.matchedLocation,
            body: const BookingsScreen(),
          ),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => MainScaffold(
            title: 'Paiements',
            location: state.matchedLocation,
            body: const PaymentsScreen(),
          ),
        ),
        GoRoute(
          path: '/reviews',
          builder: (context, state) => MainScaffold(
            title: 'Avis',
            location: state.matchedLocation,
            body: const ReviewsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => MainScaffold(
            title: 'Parametres',
            location: state.matchedLocation,
            body: const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/staff',
          builder: (context, state) => MainScaffold(
            title: 'Personnel',
            location: state.matchedLocation,
            body: const StaffScreen(),
          ),
        ),
        GoRoute(
          path: '/cleaning',
          builder: (context, state) => MainScaffold(
            title: 'Nettoyage & Controle',
            location: state.matchedLocation,
            body: const CleaningOverviewScreen(),
          ),
        ),
        GoRoute(
          path: '/performance',
          builder: (context, state) => MainScaffold(
            title: 'Performance',
            location: state.matchedLocation,
            body: const PerformanceScreen(),
          ),
        ),
      ],
    );
