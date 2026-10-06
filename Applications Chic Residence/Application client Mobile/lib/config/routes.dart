import 'package:go_router/go_router.dart';

import '../screens/booking/booking_tunnel.dart';
import '../screens/booking/bookings_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/residences/residence_detail_screen.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(
            location: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
            GoRoute(
              path: '/favorites',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FavoritesScreen()),
            ),
            GoRoute(
              path: '/bookings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BookingsScreen()),
            ),
            GoRoute(
              path: '/contact',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ContactScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/residence/:slug',
          builder: (context, state) =>
              ResidenceDetailScreen(slug: state.pathParameters['slug']!),
        ),
        GoRoute(
          path: '/book/:slug',
          builder: (context, state) =>
              BookingTunnel(slug: state.pathParameters['slug']!),
        ),
      ],
    );
