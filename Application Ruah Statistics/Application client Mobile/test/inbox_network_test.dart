import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruah_statistics_mobile/services/network.dart';
import 'package:ruah_statistics_mobile/services/notification_inbox.dart';
import 'package:ruah_statistics_mobile/services/push.dart';

InboxItem _item(String id, {bool read = false}) => InboxItem(
      id: id,
      title: 'Titre $id',
      body: 'Texte',
      receivedAt: DateTime(2026, 11, 2),
      read: read,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('la boite ignore un doublon et garde le plus recent en tete', () async {
    await InboxStore.add(_item('a'));
    await InboxStore.add(_item('b'));
    final items = await InboxStore.add(_item('a'));
    expect(items.map((e) => e.id), ['b', 'a']);
    expect((await InboxStore.load()).length, 2);
  });

  test('la boite garde 50 messages au plus', () async {
    for (var i = 0; i < 60; i++) {
      await InboxStore.add(_item('$i'));
    }
    final items = await InboxStore.load();
    expect(items.length, 50);
    expect(items.first.id, '59');
  });

  test('tout marquer lu remet le compteur a zero', () async {
    await InboxStore.add(_item('a'));
    await InboxStore.add(_item('b'));
    final notifier = InboxNotifier();
    await notifier.reload();
    expect(notifier.state.where((e) => !e.read).length, 2);
    await notifier.markAllRead();
    expect((await InboxStore.load()).every((e) => e.read), isTrue);
  });

  test('un push sans titre ni texte ne va pas dans la boite', () {
    expect(inboxItemFrom(const RemoteMessage(messageId: 'x')), isNull);
    final item = inboxItemFrom(const RemoteMessage(
      messageId: 'y',
      notification: RemoteNotification(title: 'Nouvelle étude', body: 'Lire'),
    ));
    expect(item?.id, 'y');
    expect(item?.title, 'Nouvelle étude');
  });

  test('un envoi coupe par le reseau n est jamais rejoue', () async {
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://ruah.test'));
    dio.interceptors
      ..add(RetryOnNetwork(dio))
      ..add(InterceptorsWrapper(onRequest: (o, h) {
        calls++;
        h.reject(DioException(
            requestOptions: o, type: DioExceptionType.connectionError));
      }));
    await expectLater(dio.post<void>('/leads/quote-request'),
        throwsA(isA<DioException>()));
    expect(calls, 1);
  });

  testWidgets('le bandeau hors connexion suit l etat du reseau',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: NetworkBanner(child: Scaffold(body: Text('contenu'))),
    ));
    expect(find.textContaining('Hors connexion'), findsNothing);
    NetworkStatus.online.value = false;
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    NetworkStatus.online.value = true;
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors connexion'), findsNothing);
  });
}
