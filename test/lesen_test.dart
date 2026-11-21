import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lernapp/generator/luecken.dart';
import 'package:lernapp/generator/saetze.dart';
import 'package:lernapp/generator/saetze_liste.dart';
import 'package:lernapp/generator/schreiben.dart';

const _start = ['a', 'e', 'i', 'o', 'u', 'l', 's', 'm', 'r'];

Set<String> _buchstabenVon(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '').split('').toSet();

ByteData _schrift(String n) => ByteData.sublistView(File('assets/fonts/$n').readAsBytesSync());

void main() {
  test('Sätze: zerlegen trennt Satzzeichen ab', () {
    expect(zerlegeSatz('Mi-a, sei lei-se!'), [
      (wort: 'Mi-a', zeichen: ','),
      (wort: 'sei', zeichen: ''),
      (wort: 'lei-se', zeichen: '!'),
    ]);
  });

  test('Satzliste: keine Tippfehler bei Silben (keine doppelten Bindestriche)', () {
    for (final s in saetze) {
      expect(s.contains('--') || s.contains('- ') || s.contains(' -'), isFalse, reason: s);
    }
  });

  test('Satzblatt nutzt nur gelernte Buchstaben, Sätze nach Schwierigkeit', () {
    final inhalt = erzeugeSatzblatt([..._start, 'n', 't'], seed: 1);
    expect(inhalt.saetze, hasLength(satzblattSaetzeMax));
    expect(inhalt.woerter.length + inhalt.saetze.length, satzblattReihen);
    final erlaubt = {..._start, 'n', 't'};
    for (final s in [...inhalt.saetze, ...inhalt.woerter.expand((r) => r)]) {
      expect(erlaubt.containsAll(_buchstabenVon(s)), isTrue, reason: s);
    }
    final werte = inhalt.saetze.map(satzSchwierigkeit).toList();
    expect(werte, orderedEquals([...werte]..sort()));
  });

  test('Satzblatt beachtet Ausschlüsse', () {
    final inhalt = erzeugeSatzblatt([..._start, 'n', 't'], ohne: ['ei'], seed: 2);
    for (final s in inhalt.saetze) {
      expect(s.toLowerCase().split(RegExp('[- ,.!?]')).any((t) => t.contains('ei')), isFalse);
    }
  });

  test('Lückenwörter: 24 Aufgaben, richtige Lösung immer in der Auswahl', () {
    final aufgaben = erzeugeLueckenwoerter(_start, seed: 3);
    expect(aufgaben, hasLength(lueckenProSeite));
    expect(aufgaben.map((a) => '${a.wort}|${a.stelle}').toSet(), hasLength(aufgaben.length));
    for (final a in aufgaben) {
      expect(a.wort.length, greaterThanOrEqualTo(3));
      expect(a.auswahl, contains(a.loesung));
      expect(a.auswahl.toSet(), hasLength(a.auswahl.length));
      expect(_start.toSet().containsAll(_buchstabenVon(a.wort)), isTrue);
    }
    // Stufe 1: fehlende Selbstlaute
    for (final a in aufgaben.take(8)) {
      expect('aeiouäöü'.contains(a.loesung.toLowerCase()), isTrue, reason: '$a');
    }
  });

  test('Lückenwörter: ohne passende Wörter leer', () {
    expect(erzeugeLueckenwoerter(['m', 'o']), isEmpty);
  });

  test('PDFs für Sätze, Lückenwörter und Linienblatt', () async {
    final n = _schrift('LernappSchrift-Regular.ttf'), f = _schrift('LernappSchrift-Bold.ttf');
    final pdfs = [
      await erstelleSatzPdf(erzeugeSatzblatt(_start, seed: 4), n, f),
      await erstelleLueckenPdf(_start, erzeugeLueckenwoerter(_start, seed: 4), const [], n, f),
      await erstelleLinienPdf(n, f),
    ];
    for (final pdf in pdfs) {
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    }
  });
}
