import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernapp/daten/speicher.dart';
import 'package:lernapp/main.dart';

void main() {
  testWidgets('Start: Deutsch aktiv, Mathe kommt bald; Profil anlegen', (tester) async {
    final ordner = Directory.systemTemp.createTempSync('lernapp');
    addTearDown(() => ordner.deleteSync(recursive: true));
    final daten = (await tester.runAsync(() => AppDaten.laden(ordner)))!;

    await tester.pumpWidget(LernApp(daten: daten));
    expect(find.text('Mathe'), findsOneWidget);
    expect(find.text('Kommt bald'), findsOneWidget);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leseblätter'));
    await tester.pumpAndSettle();
    expect(find.text('Kind hinzufügen'), findsOneWidget);

    await tester.runAsync(() => daten.neuesProfil('Lena'));
    await tester.pumpAndSettle();
    expect(find.text('Welche Buchstaben kann Lena schon?'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(30));

    // Ohne Buchstaben ist der Knopf gesperrt.
    final knopf = find.widgetWithText(FilledButton, 'Leseblatt erstellen');
    expect(tester.widget<FilledButton>(knopf).onPressed, isNull);
  });
}
