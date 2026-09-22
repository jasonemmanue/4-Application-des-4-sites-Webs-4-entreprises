import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/about/about_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/more/more_screen.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/projects/projects_list_screen.dart';
import '../screens/publications/article_detail_screen.dart';
import '../screens/publications/publications_screen.dart';
import '../screens/quote/quote_confirmation_screen.dart';
import '../screens/quote/quote_flow_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/services/services_list_screen.dart';
import '../screens/team/consultant_detail_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/testimonials/testimonials_screen.dart';
import '../screens/videos/videos_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String services = '/services';
  static const String serviceDetail = '/services/:slug';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:slug';
  static const String publications = '/publications';
  static const String articleDetail = '/publications/:slug';
  static const String more = '/more';
  static const String team = '/more/team';
  static const String consultantDetail = '/more/team/:id';
  static const String about = '/more/about';
  static const String videos = '/more/videos';
  static const String testimonials = '/more/testimonials';
  static const String contact = '/more/contact';
  static const String quote = '/more/quote';
  static const String quoteConfirmation = '/more/quote/confirmation';
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.search,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) =>
          MainScaffold(state: state, child: child),
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: AppRoutes.services,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ServicesListScreen()),
          routes: [
            GoRoute(
              path: ':slug',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) =>
                  ServiceDetailScreen(slug: state.pathParameters['slug']!),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.projects,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProjectsListScreen()),
          routes: [
            GoRoute(
              path: ':slug',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) =>
                  ProjectDetailScreen(slug: state.pathParameters['slug']!),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.publications,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PublicationsScreen()),
          routes: [
            GoRoute(
              path: ':slug',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) =>
                  ArticleDetailScreen(slug: state.pathParameters['slug']!),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.more,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MoreScreen()),
          routes: [
            GoRoute(
              path: 'team',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const TeamScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => ConsultantDetailScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'about',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const AboutScreen(),
            ),
            GoRoute(
              path: 'videos',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const VideosScreen(),
            ),
            GoRoute(
              path: 'testimonials',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const TestimonialsScreen(),
            ),
            GoRoute(
              path: 'contact',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const ContactScreen(),
            ),
            GoRoute(
              path: 'quote',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const QuoteFlowScreen(),
              routes: [
                GoRoute(
                  path: 'confirmation',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => QuoteConfirmationScreen(
                    reference: state.extra as String? ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
