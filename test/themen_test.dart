import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lernapp/daten/speicher.dart';
import 'package:lernapp/generator/inhalt.dart';
import 'package:lernapp/generator/saetze.dart';
import 'package:lernapp/generator/themen/leicht.dart';
import 'package:lernapp/generator/themen/themen.dart';

const _buchstaben = ['a', 'e', 'i', 'o', 'u', 'l', 's', 'm', 'r', 'n', 't', 'd', 'h'];

void main() {
  test('100 Themen mit eindeutigen Ids, jedes mit Wörtern und Sätzen', () {
    expect(alleThemen, hasLength(100));
    expect(alleThemen.map((t) => t.id).toSet(), hasLength(100));
    for (final t in alleThemen) {
      expect(t.woerter.length, greaterThanOrEqualTo(18), reason: t.id);
      expect(t.saetze.length, greaterThanOrEqualTo(8), reason: t.id);
    }
    for (final id in {...leichteWoerter.keys, ...leichteSaetze.keys}) {
      expect(themaMitId(id), isNotNull, reason: id);
    }
  });

  test('Silbentrennung: jede Silbe hat einen Selbstlaut', () {
    final vokal = RegExp('[aeiouäöüy]', caseSensitive: false);
    for (final t in alleThemen) {
      final woerter = [
        ...t.woerter,
        for (final s in t.saetze) ...zerlegeSatz(s).map((w) => w.wort),
      ];
      for (final w in woerter) {
        for (final silbe in w.split('-')) {
          expect(vokal.hasMatch(silbe), isTrue, reason: '${t.id}: $w');
        }
      }
    }
  });

  test('Mit Thema kommen Themenwörter und -sätze vor, nur aus gelernten Buchstaben', () {
    final frozen = themaMitId('frozen')!;
    final inhalt = erzeugeSatzblatt(_buchstaben, thema: frozen, seed: 5);
    expect(inhalt.thema, frozen.name);
    final themenWoerter = frozen.woerter.toSet();
    final themenSaetze = frozen.saetze.toSet();
    expect(inhalt.woerter.expand((r) => r).where(themenWoerter.contains), isNotEmpty);
    expect(inhalt.saetze.where(themenSaetze.contains), isNotEmpty);
    expect(inhalt.woerter.length + inhalt.saetze.length, satzblattReihen);
    for (final s in [...inhalt.saetze, ...inhalt.woerter.expand((r) => r)]) {
      final buchstaben = s.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '').split('');
      expect(_buchstaben.toSet().containsAll(buchstaben), isTrue, reason: s);
    }
  });

  test('Ohne passende Themenwörter wird mit dem Grundwortschatz aufgefüllt', () {
    final inhalt = erzeugeSatzblatt(
      ['a', 'e', 'i', 'o', 'u', 'l', 's', 'm', 'r'],
      thema: themaMitId('ski'),
      seed: 1,
    );
    expect(inhalt.istLeer, isFalse);
    expect(inhalt.woerter, isNotEmpty);
    expect(passendeWoerter({'a'}, AusschlussRegeln([])), isEmpty);
  });

  test('PDF mit Thema', () async {
    ByteData f(String n) => ByteData.sublistView(File('assets/fonts/$n').readAsBytesSync());
    final pdf = await erstelleSatzPdf(
      erzeugeSatzblatt(_buchstaben, thema: themaMitId('cars'), seed: 2),
      f('LernappSchrift-Regular.ttf'),
      f('LernappSchrift-Bold.ttf'),
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });

  test('Thema wird im Profil gespeichert', () async {
    final ordner = Directory.systemTemp.createTempSync('lernapp');
    addTearDown(() => ordner.deleteSync(recursive: true));
    final daten = await AppDaten.laden(ordner);
    final p = await daten.neuesProfil('Lena');
    p.thema = 'frozen';
    await daten.profilGeaendert();
    final neu = await AppDaten.laden(ordner);
    expect(neu.aktivesProfil!.thema, 'frozen');
  });
}
