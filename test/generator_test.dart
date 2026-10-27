import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lernapp/daten/speicher.dart';
import 'package:lernapp/generator/inhalt.dart';
import 'package:lernapp/generator/pdf.dart';

const beispiel = ['a', 'e', 'i', 'o', 'u', 'l', 's', 'm', 'r'];

ByteData _schrift(String name) =>
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  test('Beispiel AEIOU LSMR: 10 Reihen zu je 6, nur gelernte Buchstaben', () {
    final inhalt = erzeugeInhalt(beispiel, seed: 23);
    final reihen = [...inhalt.silben, ...inhalt.woerter];
    expect(reihen, hasLength(10));
    expect(inhalt.silben, hasLength(5));
    expect(inhalt.woerter, hasLength(5));
    for (final r in reihen) {
      expect(r, hasLength(proReihe));
      for (final e in r) {
        expect(e.replaceAll('-', '').toLowerCase().split('').every(beispiel.contains), isTrue,
            reason: e);
      }
    }
  });

  test('Wortreihen werden schwieriger', () {
    final w = erzeugeInhalt(beispiel, seed: 1).woerter;
    double schnitt(List<String> r) => r.map(schwierigkeit).reduce((a, b) => a + b) / r.length;
    for (var i = 1; i < w.length; i++) {
      expect(schnitt(w[i]), greaterThanOrEqualTo(schnitt(w[i - 1])));
    }
  });

  test('Ausschlüsse greifen bei Wörtern und Silben', () {
    final inhalt = erzeugeInhalt(beispiel,
        ohne: ['ie', 'ei', 'au', 'eu', 'ai', 'doppelvokal', 'doppelkonsonant'],
        freiOhne: 'ol',
        seed: 5);
    for (final e in [...inhalt.silben, ...inhalt.woerter].expand((r) => r)) {
      final rein = e.toLowerCase();
      for (final silbe in rein.split('-')) {
        for (final z in ['ie', 'ei', 'au', 'eu', 'ai']) {
          expect(silbe.contains(z), isFalse, reason: e);
        }
      }
      expect(RegExp(r'(.)\1').hasMatch(rein.replaceAll('-', '')), isFalse, reason: e);
      expect(rein.replaceAll('-', '').contains('ol'), isFalse, reason: e);
    }
    expect(inhalt.ausschluesse, contains('Doppelvokale'));
    expect(inhalt.ausschluesse.last, 'ol');
  });

  test('Zu wenige Wörter: Silbenreihen füllen auf', () {
    final inhalt = erzeugeInhalt(['m', 'a', 'l', 'o'], seed: 2);
    expect(inhalt.woerter.length, lessThan(5));
    expect(inhalt.silben.length, greaterThan(5));
    expect(inhalt.silben.expand((r) => r).any((s) => s.contains('-')), isTrue);
  });

  test('Ohne Selbstlaut entsteht nichts', () {
    expect(erzeugeInhalt(['m', 'l']).istLeer, isTrue);
  });

  test('PDF wird erzeugt, auch mit allen Buchstaben', () async {
    for (final b in [beispiel, alleBuchstaben]) {
      final pdf = await erstellePdf(erzeugeInhalt(b, ohne: ['h'], seed: 3),
          _schrift('Andika-Regular.ttf'), _schrift('Andika-Bold.ttf'));
      expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
      expect(pdf.length, greaterThan(10000));
    }
  });

  test('Profile und Blätter werden gespeichert und wieder geladen', () async {
    final ordner = await Directory.systemTemp.createTemp('lernapp');
    addTearDown(() => ordner.delete(recursive: true));
    final daten = await AppDaten.laden(ordner);
    final lena = await daten.neuesProfil('Lena');
    lena.buchstaben = [...beispiel];
    lena.ohne = ['ie'];
    await daten.profilGeaendert();
    final inhalt = erzeugeInhalt(lena.buchstaben, ohne: lena.ohne);
    final blatt = await daten.speichereBlatt(lena, inhalt, Uint8List.fromList([1, 2, 3]));
    expect(await daten.dateiVon(blatt).exists(), isTrue);

    final neu = await AppDaten.laden(ordner);
    expect(neu.aktivesProfil?.name, 'Lena');
    expect(neu.aktivesProfil?.buchstaben, beispiel);
    expect(neu.aktivesProfil?.ohne, ['ie']);
    expect(neu.blaetterVon(neu.aktivesProfil!), hasLength(1));

    await neu.loescheProfil(neu.aktivesProfil!);
    expect(neu.profile, isEmpty);
    expect(await daten.dateiVon(blatt).exists(), isFalse);
  });
}
