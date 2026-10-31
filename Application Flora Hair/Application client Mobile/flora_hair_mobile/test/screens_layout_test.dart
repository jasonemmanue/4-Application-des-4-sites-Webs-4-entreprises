import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flora_hair_mobile/models/category.dart';
import 'package:flora_hair_mobile/models/gallery_item.dart';
import 'package:flora_hair_mobile/models/payment.dart';
import 'package:flora_hair_mobile/models/service.dart';
import 'package:flora_hair_mobile/models/team_member.dart';
import 'package:flora_hair_mobile/screens/booking/booking_screen.dart';
import 'package:flora_hair_mobile/screens/booking/booking_state.dart';
import 'package:flora_hair_mobile/screens/favorites/favorites_screen.dart';
import 'package:flora_hair_mobile/screens/home/home_screen.dart';
import 'package:flora_hair_mobile/screens/more/more_screen.dart';
import 'package:flora_hair_mobile/screens/services/services_screen.dart';
import 'package:flora_hair_mobile/services/payment_service.dart';
import 'package:flora_hair_mobile/services/providers.dart';

/// Rendu des écrans refondus sur un petit téléphone (360 × 740), avec des
/// libellés longs : un débordement de mise en page fait échouer le test.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const service = Service(
    id: 's1',
    slug: 'tresses',
    name: 'Tresses africaines collées avec rajouts de très grande longueur',
    categoryId: 'c1',
    priceMin: 5000,
    priceMax: 12000,
    durationMinutes: 150,
  );
  const member = TeamMember(id: 't1', name: 'Aïssatou Kouassi');

  final overrides = <Override>[
    servicesProvider.overrideWith((_) async => const <Service>[service]),
    categoriesProvider.overrideWith((_) async => const <Category>[
          Category(id: 'c1', slug: 'coiffure', name: 'Coiffure Homme'),
          Category(id: 'c2', slug: 'onglerie', name: 'Onglerie'),
        ]),
    teamProvider.overrideWith((_) async => const <TeamMember>[member]),
    galleryProvider.overrideWith((_) async => const <GalleryItem>[
          GalleryItem(id: 'g1', imageUrl: '', title: 'Nattes'),
        ]),
    articlesProvider.overrideWith((_) async => const []),
    reviewsProvider.overrideWith((_) async => const []),
    paymentConfigProvider.overrideWith((_) async => const PaymentConfig(
          configured: true,
          operators: PaymentOperator.values,
        )),
  ];

  Future<ProviderContainer> pump(WidgetTester tester, Widget child,
      {void Function(ProviderContainer)? setUp}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    setUp?.call(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  testWidgets('accueil', (tester) async {
    await pump(tester, const HomeScreen());
    expect(find.text('Révélez votre'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is Image && w.semanticLabel == 'Logo Flora Hair'),
      findsOneWidget,
    );
    expect(find.text('Nos prestations'), findsOneWidget);
  });

  testWidgets('prestations', (tester) async {
    await pump(tester, const ServicesScreen());
    expect(find.text('Choisir  →'), findsOneWidget);
  });

  testWidgets('favoris vides', (tester) async {
    await pump(tester, const FavoritesScreen());
    expect(find.text('Aucun favori pour le moment'), findsOneWidget);
  });

  testWidgets('mon espace', (tester) async {
    await pump(tester, const MoreScreen());
    expect(find.text('Mon espace'), findsOneWidget);
    expect(find.text('Contacter le salon'), findsOneWidget);
  });

  testWidgets('réservation : les trois étapes', (tester) async {
    final container = await pump(tester, const BookingScreen());
    expect(find.text('Choisir mon expert·e'), findsOneWidget);

    container.read(bookingDraftProvider.notifier)
      ..setService(service)
      ..setTeamMember(member)
      ..setDate(DateTime(2030, 1, 7))
      ..setTime('10:30');
    container.read(bookingStepProvider.notifier).state = 1;
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Choisir un créneau'), findsOneWidget);

    container.read(bookingStepProvider.notifier).state = 2;
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Acompte de 50 %'), findsOneWidget);
    expect(find.text('Payer 2 500 FCFA'), findsOneWidget);

    // Les quatre logos réels sont affichés dans la grille des moyens.
    for (final op in PaymentOperator.values) {
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == op.logoAsset),
        findsOneWidget,
        reason: op.logoAsset,
      );
      expect(find.text(op.label), findsOneWidget);
    }
  });
}
