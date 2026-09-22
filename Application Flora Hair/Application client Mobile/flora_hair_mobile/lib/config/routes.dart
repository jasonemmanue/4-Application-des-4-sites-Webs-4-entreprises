import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/articles/article_detail_screen.dart';
import '../screens/articles/articles_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/home/home_screen.dart';
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
            path: '/gallery',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: GalleryScreen()),
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
          return PaymentWaitScreen(reference: ref);
        },
      ),
      GoRoute(
        path: '/payment/result',
        builder: (context, state) {
          final ref = state.uri.queryParameters['ref'] ?? '';
          final ok = state.uri.queryParameters['ok'] == '1';
          return PaymentResultScreen(reference: ref, success: ok);
        },
      ),
    ],
  );
});
