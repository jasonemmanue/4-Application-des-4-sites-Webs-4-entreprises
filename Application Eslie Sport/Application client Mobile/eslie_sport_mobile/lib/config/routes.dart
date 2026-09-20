import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/activities/activities_screen.dart';
import '../screens/activities/activity_detail_screen.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/articles/articles_screen.dart';
import '../screens/bmi/bmi_screen.dart';
import '../screens/coaches/coaches_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/enrollment/enrollment_screen.dart';
import '../screens/equipment/equipment_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/more/more_screen.dart';
import '../screens/payment/payment_result_screen.dart';
import '../screens/reviews/reviews_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/subscriptions/subscription_order_screen.dart';
import '../screens/subscriptions/subscriptions_screen.dart';
import '../screens/transformations/transformations_screen.dart';
import '../screens/videos/videos_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/activities',
            name: 'activities',
            builder: (_, __) => const ActivitiesScreen(),
          ),
          GoRoute(
            path: '/schedule',
            name: 'schedule',
            builder: (_, __) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            name: 'subscriptions',
            builder: (_, __) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (_, __) => const MoreScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/activities/:slug',
        name: 'activity-detail',
        builder: (_, state) => ActivityDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/enroll',
        name: 'enroll',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EnrollmentScreen(
            activitySlug: extra?['activitySlug'] as String?,
            slotId: extra?['slotId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/subscriptions/order/:slug',
        name: 'subscription-order',
        builder: (_, state) => SubscriptionOrderScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/payment/result',
        name: 'payment-result',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentResultScreen(
            reference: extra?['reference'] as String? ?? '',
            success: extra?['success'] as bool? ?? false,
            message: extra?['message'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/coaches',
        name: 'coaches',
        builder: (_, __) => const CoachesScreen(),
      ),
      GoRoute(
        path: '/equipment',
        name: 'equipment',
        builder: (_, __) => const EquipmentScreen(),
      ),
      GoRoute(
        path: '/articles',
        name: 'articles',
        builder: (_, __) => const ArticlesScreen(),
      ),
      GoRoute(
        path: '/articles/:slug',
        name: 'article-detail',
        builder: (_, state) => ArticleDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/videos',
        name: 'videos',
        builder: (_, __) => const VideosScreen(),
      ),
      GoRoute(
        path: '/transformations',
        name: 'transformations',
        builder: (_, __) => const TransformationsScreen(),
      ),
      GoRoute(
        path: '/reviews',
        name: 'reviews',
        builder: (_, __) => const ReviewsScreen(),
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        path: '/bmi',
        name: 'bmi',
        builder: (_, __) => const BmiScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});
