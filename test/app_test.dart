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
    expect(find.text('Schreibblätter'), findsOneWidget);
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

  testWidgets('Schreibblätter: Buchstaben wählen schaltet den Knopf frei', (tester) async {
    final ordner = Directory.systemTemp.createTempSync('lernapp');
    addTearDown(() => ordner.deleteSync(recursive: true));
    final daten = (await tester.runAsync(() async {
      final d = await AppDaten.laden(ordner);
      await d.neuesProfil('Max');
      return d;
    }))!;

    await tester.pumpWidget(LernApp(daten: daten));
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schreibblätter'));
    await tester.pumpAndSettle();
    expect(find.text('Welche Buchstaben kann Max schon?'), findsOneWidget);

    final knopf = find.widgetWithText(FilledButton, 'Schreibblatt erstellen');
    expect(tester.widget<FilledButton>(knopf).onPressed, isNull);
    await tester.tap(find.text('Mm'));
    await tester.pump();
    expect(tester.widget<FilledButton>(knopf).onPressed, isNotNull);
    expect(find.text('1 Seite mit je 8 Zeilen'), findsOneWidget);
    expect(daten.aktivesProfil!.buchstaben, ['m']);

    // Dieselbe Auswahl gilt auch für die Leseblätter.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leseblätter'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Mm')).selected, isTrue);
  });
}
