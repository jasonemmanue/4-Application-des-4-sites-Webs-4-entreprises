import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flora_hair_mobile/app.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('L\'application demarre sans crasher', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FloraHairApp()));
    // On laisse un frame passer, sans exiger de golden path pour ce smoke test.
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Vide les minuteries de l'accueil et des appels réseau (refusés en test).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 1));
  });
}
