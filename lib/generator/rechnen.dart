/// Rechenblatt: Aufgaben mit den gewählten Rechenarten im Zahlenraum des
/// Kindes, mit Kästchen für das Ergebnis.
///
/// Regeln: Im Zahlenraum 20 werden nur einstellige Zahlen (1–9) verwendet.
/// Ergebnisse bleiben immer im Zahlenraum, Minus wird nie negativ, Geteilt
/// geht immer ohne Rest auf. Die Zahl 0 kommt nicht vor.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'pdf.dart';

enum Rechenart {
  plus('+', 'Plus'),
  minus('−', 'Minus'),
  mal('·', 'Mal'),
  geteilt(':', 'Geteilt');

  const Rechenart(this.zeichen, this.bezeichnung);

  final String zeichen;
  final String bezeichnung;
}

const zahlenraumMin = 20;
const zahlenraumMax = 1000;
const aufgabenProSeite = 24;

class Aufgabe {
  const Aufgabe(this.a, this.art, this.b);

  final int a;
  final Rechenart art;
  final int b;

  int get ergebnis => switch (art) {
    Rechenart.plus => a + b,
    Rechenart.minus => a - b,
    Rechenart.mal => a * b,
    Rechenart.geteilt => a ~/ b,
  };

  /// Grobe Schwierigkeit: die größte vorkommende Zahl.
  int get groesse => math.max(math.max(a, b), ergebnis);

  @override
  String toString() => '$a ${art.zeichen} $b';

  @override
  bool operator ==(Object other) =>
      other is Aufgabe && other.a == a && other.b == b && other.art == art;

  @override
  int get hashCode => Object.hash(a, art, b);
}

int _faktorGrenze(int zahlenraum) => zahlenraum <= zahlenraumMin
    ? 9
    : zahlenraum <= 100
    ? 10
    : zahlenraum;

/// Eine zufällige Aufgabe der Rechenart im Zahlenraum.
Aufgabe _aufgabe(Rechenart art, int zahlenraum, math.Random rng) {
  // Im Zahlenraum 20 nur einstellige Zahlen.
  final grenze = zahlenraum <= zahlenraumMin ? 9 : zahlenraum - 1;
  int zahl(int von, int bis) => von + rng.nextInt(bis - von + 1);
  switch (art) {
    case Rechenart.plus:
      final a = zahl(1, math.min(grenze, zahlenraum - 1));
      return Aufgabe(a, art, zahl(1, math.min(grenze, zahlenraum - a)));
    case Rechenart.minus:
      final a = zahl(2, math.min(grenze, zahlenraum));
      return Aufgabe(a, art, zahl(1, a - 1));
    case Rechenart.mal:
      // ·1 ist zu leicht, daher ab 2. Ein Faktor ist immer höchstens 10
      // (Einmaleins), bis 100 auch der andere.
      final a = zahl(2, math.min(math.min(10, _faktorGrenze(zahlenraum)), zahlenraum ~/ 2));
      return Aufgabe(a, art, zahl(2, math.min(_faktorGrenze(zahlenraum), zahlenraum ~/ a)));
    case Rechenart.geteilt:
      final b = zahl(2, math.min(math.min(10, _faktorGrenze(zahlenraum)), zahlenraum ~/ 2));
      final ergebnis = zahl(2, math.min(_faktorGrenze(zahlenraum), zahlenraum ~/ b));
      return Aufgabe(b * ergebnis, art, b);
  }
}

/// Aufgaben für ein Blatt: die Rechenarten gleichmäßig gemischt, möglichst
/// ohne Wiederholung, von leicht nach schwer sortiert.
List<Aufgabe> erzeugeAufgaben(
  List<Rechenart> arten,
  int zahlenraum, {
  int anzahl = aufgabenProSeite,
  int? seed,
}) {
  if (arten.isEmpty) return [];
  final raum = zahlenraum.clamp(zahlenraumMin, zahlenraumMax);
  final rng = math.Random(seed);
  final aufgaben = <Aufgabe>[];
  for (var i = 0; i < anzahl; i++) {
    final art = arten[i % arten.length];
    var neu = _aufgabe(art, raum, rng);
    // Doppelte Aufgaben vermeiden, solange es genug andere gibt.
    for (var versuch = 0; versuch < 50 && aufgaben.contains(neu); versuch++) {
      neu = _aufgabe(art, raum, rng);
    }
    aufgaben.add(neu);
  }
  aufgaben.shuffle(rng);
  // Stabil nach Schwierigkeit sortieren, die Rechenarten bleiben gemischt.
  final sortiert = aufgaben.indexed.toList()
    ..sort((x, y) {
      final c = x.$2.groesse.compareTo(y.$2.groesse);
      return c != 0 ? c : x.$1.compareTo(y.$1);
    });
  return [for (final (_, a) in sortiert) a];
}

class _Farben {
  static final band = PdfColor.fromHex('#E8F5E9');
  static final kaestchen = PdfColor.fromHex('#90A4AE');
  static final stern = PdfColor.fromHex('#F4A261');
}

/// Erstellt das Rechenblatt (eine Seite, 24 Aufgaben in zwei Spalten).
Future<Uint8List> erstelleRechenPdf(
  List<Rechenart> arten,
  int zahlenraum,
  ByteData schrift,
  ByteData schriftFett, {
  int? seed,
}) {
  final raum = zahlenraum.clamp(zahlenraumMin, zahlenraumMax);
  final aufgaben = erzeugeAufgaben(arten, raum, seed: seed);
  final doc = PdfDocument();
  PdfInfo(doc, title: 'Mein Rechenblatt – bis $raum', creator: 'Lernapp');
  final format = PdfPageFormat.a4;
  final breite = format.width, hoehe = format.height;
  const rand = 13 * mm;
  final z = Zeichner(
    PdfPage(doc, pageFormat: format).getGraphics(),
    PdfTtfFont(doc, schrift),
    PdfTtfFont(doc, schriftFett),
  );

  final sortiertArten = Rechenart.values.where(arten.contains).toList();
  final y = zeichneKopf(
    z,
    [for (final a in sortiertArten) a.zeichen],
    breite,
    hoehe,
    rand,
    titel: 'Mein Rechenblatt',
    label: 'Ich rechne bis $raum:',
    hinweis: 'Rechne und schreibe das Ergebnis ins Kästchen. Reihe fertig? Male den Stern an!',
  );

  const zeilen = aufgabenProSeite ~/ 2;
  const sternBreite = 12 * mm, luecke = 6 * mm;
  final hoeheZeile = math.min(19 * mm, (y - rand - 4 * mm) / zeilen);
  final spalte = (breite - 2 * rand - sternBreite - luecke) / 2;
  int laenge(int Function(Aufgabe) zahl) =>
      aufgaben.map((a) => '${zahl(a)}'.length).fold(1, math.max);
  final stellen = laenge((a) => math.max(a.a, a.b));
  final groesse = math.min(24.0, hoeheZeile * 0.5);
  final kaestchenBreite = (laenge((a) => a.ergebnis) + 0.8) * z.breite('0', groesse);
  final kaestchenHoehe = hoeheZeile * 0.62;

  for (var i = 0; i < zeilen; i++) {
    final oben = y - i * hoeheZeile;
    final unten = oben - hoeheZeile;
    final mitte = (oben + unten) / 2;
    z.rundesRechteck(rand, unten + 1.2, breite - 2 * rand, hoeheZeile - 2.4, 7, _Farben.band);

    for (var s = 0; s < 2; s++) {
      final aufgabe = aufgaben[i * 2 + s];
      final x0 = rand + 4 * mm + s * (spalte + luecke);
      final grundlinie = mitte - groesse * 0.3;
      // Zahlen rechtsbündig, damit die Rechenzeichen untereinander stehen.
      final zahlBreite = stellen * z.breite('0', groesse);
      final zeichenBreite = z.breite(' + ', groesse);
      var x = x0;
      z.textRechts('${aufgabe.a}', x + zahlBreite, grundlinie, groesse, BlattFarben.text);
      x += zahlBreite;
      z.textMitte(
        aufgabe.art.zeichen,
        x + zeichenBreite / 2,
        grundlinie,
        groesse,
        BlattFarben.text,
      );
      x += zeichenBreite;
      z.textRechts('${aufgabe.b}', x + zahlBreite, grundlinie, groesse, BlattFarben.text);
      x += zahlBreite;
      z.textMitte('=', x + zeichenBreite / 2, grundlinie, groesse, BlattFarben.text);
      x += zeichenBreite;

      z.rundesRechteck(
        x,
        mitte - kaestchenHoehe / 2,
        kaestchenBreite,
        kaestchenHoehe,
        5,
        PdfColors.white,
      );
      z.g
        ..setStrokeColor(_Farben.kaestchen)
        ..setLineWidth(1)
        ..drawRRect(x, mitte - kaestchenHoehe / 2, kaestchenBreite, kaestchenHoehe, 5, 5)
        ..strokePath();
    }

    z.g
      ..setStrokeColor(_Farben.stern)
      ..setLineWidth(1.3);
    z.stern(breite - rand - sternBreite / 2, mitte, 4.2 * mm);
  }
  return doc.save();
}
