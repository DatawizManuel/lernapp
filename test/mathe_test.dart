import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernapp/daten/speicher.dart';
import 'package:lernapp/generator/rechnen.dart';
import 'package:lernapp/generator/schreiben.dart';
import 'package:lernapp/main.dart';

ByteData _schrift(String name) =>
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  test('Zahlenraum 20: nur einstellige Zahlen, Ergebnisse im Zahlenraum', () {
    for (var seed = 0; seed < 50; seed++) {
      for (final a in erzeugeAufgaben(Rechenart.values, 20, seed: seed)) {
        expect(a.a, inInclusiveRange(1, 20), reason: '$a');
        expect(a.b, inInclusiveRange(1, 9), reason: '$a');
        if (a.art != Rechenart.geteilt) expect(a.a, lessThanOrEqualTo(9), reason: '$a');
        expect(a.ergebnis, inInclusiveRange(1, 20), reason: '$a');
        if (a.art == Rechenart.geteilt) expect(a.a % a.b, 0, reason: '$a');
      }
    }
  });

  test('Zahlenraum 100: Ergebnisse im Zahlenraum, Einmaleins bei Mal/Geteilt', () {
    for (var seed = 0; seed < 50; seed++) {
      final aufgaben = erzeugeAufgaben(Rechenart.values, 100, seed: seed);
      expect(aufgaben, hasLength(aufgabenProSeite));
      for (final a in aufgaben) {
        expect(a.ergebnis, inInclusiveRange(1, 100), reason: '$a');
        expect(a.a, lessThanOrEqualTo(100), reason: '$a');
        if (a.art == Rechenart.mal) {
          expect(a.a, lessThanOrEqualTo(10), reason: '$a');
          expect(a.b, lessThanOrEqualTo(10), reason: '$a');
        }
        if (a.art == Rechenart.geteilt) {
          expect(a.b, lessThanOrEqualTo(10), reason: '$a');
          expect(a.ergebnis, lessThanOrEqualTo(10), reason: '$a');
        }
      }
    }
  });

  test('Rechenarten werden gleichmäßig gemischt', () {
    final aufgaben = erzeugeAufgaben([Rechenart.plus, Rechenart.minus], 20, seed: 1);
    expect(aufgaben.where((a) => a.art == Rechenart.plus), hasLength(12));
    expect(aufgaben.where((a) => a.art == Rechenart.minus), hasLength(12));
    expect(erzeugeAufgaben([], 20), isEmpty);
  });

  test('PDFs werden erzeugt', () async {
    final r = _schrift('LernappSchrift-Regular.ttf'), b = _schrift('LernappSchrift-Bold.ttf');
    for (final raum in [20, 100, 1000]) {
      final pdf = await erstelleRechenPdf(Rechenart.values, raum, r, b);
      expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    }
    final zahlen = await erstelleZahlenSchreibPdf(alleZiffern, r, b);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(zahlen)).length, 2);
    expect(zahlenZeilen(['3', '1']), ['1', '3', '1', '3', '1', '3', '1', '3']);
  });

  test('Mathe-Einstellungen werden pro Kind gespeichert', () async {
    final ordner = await Directory.systemTemp.createTemp('lernapp');
    addTearDown(() => ordner.delete(recursive: true));
    final daten = await AppDaten.laden(ordner);
    final p = await daten.neuesProfil('Max');
    expect(p.zahlenraum, 20);
    expect(p.rechenarten, [Rechenart.plus]);
    expect(p.ziffern, alleZiffern);
    p
      ..zahlenraum = 100
      ..rechenarten = [Rechenart.plus, Rechenart.mal]
      ..ziffern = ['1', '2'];
    await daten.profilGeaendert();

    final q = (await AppDaten.laden(ordner)).aktivesProfil!;
    expect(q.zahlenraum, 100);
    expect(q.rechenarten, [Rechenart.plus, Rechenart.mal]);
    expect(q.ziffern, ['1', '2']);
  });

  testWidgets('Mathe: Rechenblatt-Seite prüft den Zahlenraum', (tester) async {
    final ordner = Directory.systemTemp.createTempSync('lernapp');
    addTearDown(() => ordner.deleteSync(recursive: true));
    final daten = (await tester.runAsync(() async {
      final d = await AppDaten.laden(ordner);
      await d.neuesProfil('Max');
      return d;
    }))!;

    await tester.pumpWidget(LernApp(daten: daten));
    await tester.tap(find.text('Mathe'));
    await tester.pumpAndSettle();
    expect(find.text('Zahlen schreiben'), findsOneWidget);
    await tester.tap(find.text('Rechenblätter'));
    await tester.pumpAndSettle();

    final knopf = find.widgetWithText(FilledButton, 'Rechenblatt erstellen');
    expect(tester.widget<FilledButton>(knopf).onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), '15');
    await tester.pump();
    expect(find.text('Bitte eine Zahl von 20 bis 1000'), findsOneWidget);
    expect(tester.widget<FilledButton>(knopf).onPressed, isNull);
    expect(daten.aktivesProfil!.zahlenraum, 20);

    await tester.enterText(find.byType(TextField), '100');
    await tester.pump();
    expect(tester.widget<FilledButton>(knopf).onPressed, isNotNull);
    expect(daten.aktivesProfil!.zahlenraum, 100);
  });
}
