import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ruah_statistics_mobile/config/api_config.dart';
import 'package:ruah_statistics_mobile/config/routes.dart';
import 'package:ruah_statistics_mobile/config/theme.dart';
import 'package:ruah_statistics_mobile/models/project.dart';
import 'package:ruah_statistics_mobile/models/service.dart';
import 'package:ruah_statistics_mobile/providers/providers.dart';
import 'package:ruah_statistics_mobile/screens/contact/contact_hub_screen.dart';
import 'package:ruah_statistics_mobile/screens/home/home_screen.dart';
import 'package:ruah_statistics_mobile/screens/main_scaffold.dart';
import 'package:ruah_statistics_mobile/screens/services/services_list_screen.dart';
import 'package:ruah_statistics_mobile/services/api_client.dart';
import 'package:ruah_statistics_mobile/widgets/ruah_ui.dart';

const _services = [
  Service(id: '1', slug: 'etudes-de-faisabilite', title: 'Études de Faisabilité'),
  Service(id: '2', slug: 'conseil-en-strategie', title: 'Conseil en Stratégie'),
  Service(id: '3', slug: 'etudes-dimpact', title: "Études d'Impact"),
  Service(id: '4', slug: 'audit-et-evaluation', title: 'Audit & Évaluation'),
  Service(id: '5', slug: 'formation-et-renforcement', title: 'Formation & Renforcement'),
];

const _project = Project(
  id: 'p',
  slug: 'centrale-solaire-50mw',
  title: 'Centrale solaire 50MW',
  isFeatured: true,
);

Widget _host(Widget child, {String location = '/'}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (c, s, shellChild) =>
            MainScaffold(state: s, child: shellChild),
        routes: [GoRoute(path: location, builder: (c, s) => child)],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      servicesProvider.overrideWith((ref) async => _services),
      keyFiguresProvider.overrideWith((ref) async => const []),
      projectsProvider.overrideWith(
        (ref, filter) async => const PagedResult<Project>(
            items: [_project], page: 1, totalPages: 1, total: 1),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void _phone(WidgetTester tester, double height) {
  tester.view.physicalSize = Size(1170, height);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('resolveMediaUrl', () {
    test('une URL absolue reste telle quelle', () {
      expect(ApiConfig.resolveMediaUrl('https://x.test/a.jpg'),
          'https://x.test/a.jpg');
    });
    test('un fichier televerse depuis l admin vise la racine du serveur', () {
      expect(ApiConfig.resolveMediaUrl('/uploads/services/a.png'),
          '${ApiConfig.uploadsBase}/uploads/services/a.png');
      expect(ApiConfig.uploadsBase.endsWith('/api/v1'), isFalse);
    });
    test('une valeur vide ne donne pas d image', () {
      expect(ApiConfig.resolveMediaUrl(''), isNull);
      expect(ApiConfig.resolveMediaUrl('  '), isNull);
      expect(ApiConfig.resolveMediaUrl(null), isNull);
    });
  });

  test('la couverture du projet vient de images[0]', () {
    final p = Project.fromJson(const {
      'id': '1',
      'slug': 's',
      'title': 't',
      'images': ['/uploads/a.jpg'],
      'client_logo_url': '/uploads/logo.png',
    });
    expect(p.coverImage, '${ApiConfig.uploadsBase}/uploads/a.jpg');
  });

  testWidgets('avatar sans photo : initiales sans le titre Dr.',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: RemoteAvatar(url: '', name: 'Dr. Amadou Diallo'),
    ));
    expect(find.text('AD'), findsOneWidget);
  });

  testWidgets('accueil : logo, expertises, filtre et projet a la une',
      (tester) async {
    _phone(tester, 2532);
    await tester.pumpWidget(_host(const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/images/logo.png'),
      findsOneWidget,
    );
    expect(find.text('Conseil en Stratégie'), findsOneWidget);
    expect(find.text('Projet à la une'), findsOneWidget);
    expect(find.text('Centrale solaire 50MW'), findsOneWidget);

    await tester.tap(find.text('Stratégie'));
    await tester.pump();
    expect(find.text('Conseil en Stratégie'), findsOneWidget);
    expect(find.text('Audit & Évaluation'), findsNothing);
  });

  testWidgets('services : la liste montre toutes les expertises',
      (tester) async {
    _phone(tester, 4000);
    await tester.pumpWidget(
        _host(const ServicesListScreen(), location: AppRoutes.services));
    await tester.pump(const Duration(milliseconds: 100));
    for (final s in _services) {
      expect(find.text(s.title), findsOneWidget);
    }
  });

  testWidgets('contact : formulaire vide refuse', (tester) async {
    _phone(tester, 3400);
    await tester.pumpWidget(
        _host(const ContactHubScreen(), location: AppRoutes.contact));
    await tester.pump();
    await tester.tap(find.text('Demander un devis'));
    await tester.pump();
    expect(find.text('Requis'), findsWidgets);
    expect(find.text('Choisissez un type de besoin'), findsOneWidget);
  });
}
