import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lernapp/daten/speicher.dart';
import 'package:lernapp/generator/inhalt.dart';
import 'package:lernapp/generator/schreiben.dart';

ByteData _schrift(String name) =>
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  test('Zeilen: groß und klein, aufgefüllt bis die Seite voll ist', () {
    expect(schreibZeilen(['m', 'a'], SchreibForm.beide), ['A', 'a', 'M', 'm', 'A', 'a', 'M', 'm']);
    expect(schreibZeilen(['m'], SchreibForm.gross), List.filled(8, 'M'));
    expect(
      schreibZeilen(['ß', 'a'], SchreibForm.gross),
      List.filled(8, 'A').toList()
        ..setAll(1, ['ß'])
        ..setAll(3, ['ß'])
        ..setAll(5, ['ß'])
        ..setAll(7, ['ß']),
    );
    expect(schreibZeilen([], SchreibForm.beide), isEmpty);
    expect(schreibZeilen(alleBuchstaben, SchreibForm.beide).length % schreibZeilenProSeite, 0);
  });

  test('Jeder auswählbare Buchstabe ist groß und klein hinterlegt', () {
    for (final b in alleBuchstaben) {
      expect(kannSchreiben(b), isTrue, reason: b);
      if (b != 'ß') expect(kannSchreiben(b.toUpperCase()), isTrue, reason: b.toUpperCase());
    }
  });

  test('PDF wird erzeugt, mehrseitig bei vielen Buchstaben', () async {
    final pdf = await erstelleSchreibPdf(
      alleBuchstaben,
      SchreibForm.beide,
      _schrift('LernappSchrift-Regular.ttf'),
      _schrift('LernappSchrift-Bold.ttf'),
    );
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(pdf)).length, 8);
  });

  test('Schreib-Auswahl und Blatt-Art werden gespeichert', () async {
    final ordner = await Directory.systemTemp.createTemp('lernapp');
    addTearDown(() => ordner.delete(recursive: true));
    final daten = await AppDaten.laden(ordner);
    final p = await daten.neuesProfil('Max');
    p.schreibBuchstaben = ['a', 'm'];
    p.schreibForm = SchreibForm.klein;
    await daten.profilGeaendert();
    await daten.speichereBlatt(p, BlattArt.schreiben, Uint8List(3), buchstaben: ['a', 'm']);

    final neu = await AppDaten.laden(ordner);
    final q = neu.aktivesProfil!;
    expect(q.schreibBuchstaben, ['a', 'm']);
    expect(q.schreibForm, SchreibForm.klein);
    expect(neu.blaetterVon(q, BlattArt.schreiben), hasLength(1));
    expect(neu.blaetterVon(q, BlattArt.lesen), isEmpty);
    expect(neu.blaetterVon(q).single.datei, startsWith('Schreibblatt_Max_'));
  });

  test('Alte Profile ohne Schreib-Felder lassen sich laden', () {
    final p = Profil.fromJson({
      'id': '1',
      'name': 'Lena',
      'buchstaben': ['a'],
    });
    expect(p.schreibBuchstaben, isEmpty);
    expect(p.schreibForm, SchreibForm.beide);
    final b = GespeichertesBlatt.fromJson({
      'datei': 'x.pdf',
      'profilId': '1',
      'erstellt': '2026-10-27T10:00:00',
      'buchstaben': [],
    });
    expect(b.art, BlattArt.lesen);
  });
}
