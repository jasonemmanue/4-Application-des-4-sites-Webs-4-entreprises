import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/payment.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/articles/articles_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inbox/inbox_screen.dart';
import '../screens/more/faq_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/payment/payment_result_screen.dart';
import '../screens/payment/payment_wait_screen.dart';
import '../screens/quote/quote_screen.dart';
import '../screens/reviews/reviews_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/training/training_screen.dart';
import '../screens/videos/videos_screen.dart';
import '../widgets/root_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/services',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ServicesScreen()),
          ),
          GoRoute(
            path: '/booking',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: BookingScreen()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: FavoritesScreen()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: MoreScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/services/:slug',
        builder: (context, state) =>
            ServiceDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => AppointmentsScreen(
          initialTab: state.uri.queryParameters['tab'] == 'history' ? 1 : 0,
        ),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
      GoRoute(path: '/team', builder: (_, __) => const TeamScreen()),
      GoRoute(path: '/articles', builder: (_, __) => const ArticlesScreen()),
      GoRoute(
        path: '/articles/:slug',
        builder: (context, state) =>
            ArticleDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/videos', builder: (_, __) => const VideosScreen()),
      GoRoute(path: '/reviews', builder: (_, __) => const ReviewsScreen()),
      GoRoute(path: '/quote', builder: (_, __) => const QuoteScreen()),
      GoRoute(path: '/training', builder: (_, __) => const TrainingScreen()),
      GoRoute(path: '/contact', builder: (_, __) => const ContactScreen()),
      GoRoute(
        path: '/payment/wait',
        builder: (context, state) {
          final ref = state.uri.queryParameters['ref'] ?? '';
          return PaymentWaitScreen(
            reference: ref,
            operator:
                paymentOperatorFromCode(state.uri.queryParameters['op']),
          );
        },
      ),
      GoRoute(
        path: '/payment/result',
        builder: (context, state) {
          final ref = state.uri.queryParameters['ref'] ?? '';
          return PaymentResultScreen(reference: ref);
        },
      ),
    ],
  );
});
