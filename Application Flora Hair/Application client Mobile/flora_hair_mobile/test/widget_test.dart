import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flora_hair_mobile/app.dart';

void main() {
  testWidgets('L\'application demarre sans crasher', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FloraHairApp()));
    // On laisse un frame passer, sans exiger de golden path pour ce smoke test.
    await tester.pump();
  });
}
