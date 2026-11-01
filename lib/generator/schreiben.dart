/// Schreibblatt: Buchstaben zum Nachfahren und Üben auf Hilfslinien.
///
/// Jede Zeile beginnt mit dem Buchstaben als Vorlage (mit grünen
/// Startpunkten), danach zweimal strichliert zum Nachfahren, der Rest der
/// Zeile bleibt frei. Die Buchstaben sind als einfache Striche hinterlegt
/// (keine Schrift), damit die Vorlage genau so aussieht, wie das Kind
/// den Buchstaben schreibt.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'inhalt.dart' show alleBuchstaben, sortiereBuchstaben;
import 'pdf.dart';

/// Welche Formen der Buchstaben geübt werden.
enum SchreibForm { beide, gross, klein }

const schreibZeilenProSeite = 8;

// Strichzeichnungen der Buchstaben. Einheiten: Grundlinie y=0,
// Mittellinie y=1, Oberlinie y=2, Unterlinie y=-1.
// Befehle: M x y (Stift absetzen), L x y (Linie), P x y (Punkt),
// A cx cy rx ry von bis (Ellipsenbogen, Winkel in Grad, gegen den
// Uhrzeigersinn positiv). Striche werden mit ";" getrennt und stehen in
// Schreibrichtung.
const _glyphen = <String, (double, String)>{
  'a': (0.8, 'A .4 .5 .4 .5 30 390; M .8 1 L .8 0'),
  'b': (0.8, 'M 0 2 L 0 0; A .4 .5 .4 .5 180 -180'),
  'c': (0.75, 'A .4 .5 .4 .5 45 315'),
  'd': (0.8, 'A .4 .5 .4 .5 30 390; M .8 2 L .8 0'),
  'e': (0.8, 'M 0 .5 L .8 .5 A .4 .5 .4 .5 0 315'),
  'f': (0.6, 'A .55 1.6 .25 .25 30 180 L .3 0; M 0 1 L .6 1'),
  'g': (0.8, 'A .4 .5 .4 .5 30 390; M .8 1 L .8 -.6 A .4 -.6 .4 .35 0 -160'),
  'h': (0.8, 'M 0 2 L 0 0; M 0 .6 A .4 .6 .4 .4 180 0 L .8 0'),
  'i': (0, 'M 0 1 L 0 0; P 0 1.45'),
  'j': (0.45, 'M .4 1 L .4 -.6 A .1 -.6 .3 .3 0 -160; P .4 1.45'),
  'k': (0.75, 'M 0 2 L 0 0; M .7 1 L .05 .45 L .75 0'),
  'l': (0.4, 'M 0 2 L 0 .25 A .25 .25 .25 .25 180 300'),
  'm': (1.2, 'M 0 1 L 0 0; M 0 .6 A .3 .6 .3 .4 180 0 L .6 0; M .6 .6 A .9 .6 .3 .4 180 0 L 1.2 0'),
  'n': (0.8, 'M 0 1 L 0 0; M 0 .6 A .4 .6 .4 .4 180 0 L .8 0'),
  'o': (0.9, 'A .45 .5 .45 .5 90 450'),
  'p': (0.8, 'M 0 1 L 0 -1; A .4 .5 .4 .5 180 -180'),
  'q': (0.8, 'A .4 .5 .4 .5 30 390; M .8 1 L .8 -1'),
  'r': (0.6, 'M 0 1 L 0 0; M 0 .6 A .4 .6 .4 .4 180 60'),
  's': (0.7, 'A .35 .75 .35 .25 20 270 A .35 .25 .35 .25 90 -160'),
  't': (0.6, 'M .2 1.6 L .2 .25 A .45 .25 .25 .25 180 300; M 0 1 L .6 1'),
  'u': (0.8, 'M 0 1 L 0 .4 A .4 .4 .4 .4 180 360; M .8 1 L .8 0'),
  'v': (0.8, 'M 0 1 L .4 0 L .8 1'),
  'w': (1.2, 'M 0 1 L .3 0 L .6 1 L .9 0 L 1.2 1'),
  'x': (0.8, 'M 0 1 L .8 0; M .8 1 L 0 0'),
  'y': (0.8, 'M 0 1 L .475 0; M .8 1 L .15 -1'),
  'z': (0.8, 'M 0 1 L .8 1 L 0 0 L .8 0'),
  'ä': (0.8, 'A .4 .5 .4 .5 30 390; M .8 1 L .8 0; P .2 1.4; P .6 1.4'),
  'ö': (0.9, 'A .45 .5 .45 .5 90 450; P .25 1.4; P .65 1.4'),
  'ü': (0.8, 'M 0 1 L 0 .4 A .4 .4 .4 .4 180 360; M .8 1 L .8 0; P .2 1.4; P .6 1.4'),
  'ß': (
    0.75,
    'M 0 0 L 0 1.5 A .35 1.5 .35 .45 180 -70 L .3 1.05 '
        'A .35 .5 .4 .55 85 -160',
  ),
  'A': (1.4, 'M .7 2 L 0 0; M .7 2 L 1.4 0; M .25 .7 L 1.15 .7'),
  'B': (
    1.15,
    'M 0 2 L 0 0; M 0 2 L .6 2 A .6 1.5 .45 .5 90 -90 L 0 1; '
        'M .6 1 A .6 .5 .55 .5 90 -90 L 0 0',
  ),
  'C': (1.5, 'A .9 1 .9 1 50 310'),
  'D': (1.3, 'M 0 2 L 0 0; M 0 2 L .4 2 A .4 1 .9 1 90 -90 L 0 0'),
  'E': (1, 'M 1 2 L 0 2 L 0 0 L 1 0; M 0 1 L .85 1'),
  'F': (1, 'M 1 2 L 0 2 L 0 0; M 0 1 L .85 1'),
  'G': (1.8, 'A .9 1 .9 1 50 360 L 1.1 1'),
  'H': (1.2, 'M 0 2 L 0 0; M 1.2 2 L 1.2 0; M 0 1 L 1.2 1'),
  'I': (0, 'M 0 2 L 0 0'),
  'J': (0.8, 'M .8 2 L .8 .5 A .4 .5 .4 .5 0 -180'),
  'K': (1.15, 'M 0 2 L 0 0; M 1.1 2 L .05 .9 L 1.15 0'),
  'L': (0.9, 'M 0 2 L 0 0 L .9 0'),
  'M': (1.6, 'M 0 0 L 0 2 L .8 .6 L 1.6 2 L 1.6 0'),
  'N': (1.2, 'M 0 0 L 0 2 L 1.2 0 L 1.2 2'),
  'O': (2, 'A 1 1 1 1 90 450'),
  'P': (1.1, 'M 0 2 L 0 0; M 0 2 L .6 2 A .6 1.5 .5 .5 90 -90 L 0 1'),
  'Q': (2, 'A 1 1 1 1 90 450; M 1.2 .45 L 1.95 -.25'),
  'R': (1.2, 'M 0 2 L 0 0; M 0 2 L .6 2 A .6 1.5 .5 .5 90 -90 L 0 1 L .45 1 L 1.2 0'),
  'S': (1.3, 'A .65 1.5 .6 .5 20 270 A .65 .5 .65 .5 90 -160'),
  'T': (1.4, 'M 0 2 L 1.4 2; M .7 2 L .7 0'),
  'U': (1.2, 'M 0 2 L 0 .7 A .6 .7 .6 .7 180 360 L 1.2 2'),
  'V': (1.4, 'M 0 2 L .7 0 L 1.4 2'),
  'W': (2, 'M 0 2 L .5 0 L 1 2 L 1.5 0 L 2 2'),
  'X': (1.2, 'M 0 2 L 1.2 0; M 1.2 2 L 0 0'),
  'Y': (1.3, 'M 0 2 L .65 1; M 1.3 2 L .65 1 L .65 0'),
  'Z': (1.2, 'M 0 2 L 1.2 2 L 0 0 L 1.2 0'),
  'Ä': (1.4, 'M .7 2 L 0 0; M .7 2 L 1.4 0; M .25 .7 L 1.15 .7; P .45 2.35; P .95 2.35'),
  'Ö': (2, 'A 1 1 1 1 90 450; P .75 2.35; P 1.25 2.35'),
  'Ü': (1.2, 'M 0 2 L 0 .7 A .6 .7 .6 .7 180 360 L 1.2 2; P .35 2.35; P .85 2.35'),
};

class _Strich {
  _Strich(this.punkte, {this.istPunkt = false});

  final List<(double, double)> punkte;
  final bool istPunkt;
}

List<_Strich> _striche(String code) {
  final striche = <_Strich>[];
  for (final teil in code.split(';')) {
    final t = teil.trim().split(RegExp(r'\s+'));
    final punkte = <(double, double)>[];
    var i = 0;
    double zahl() => double.parse(t[++i]);
    for (; i < t.length; i++) {
      switch (t[i]) {
        case 'M' || 'L':
          punkte.add((zahl(), zahl()));
        case 'P':
          striche.add(_Strich([(zahl(), zahl())], istPunkt: true));
        case 'A':
          final (cx, cy, rx, ry, von, bis) = (zahl(), zahl(), zahl(), zahl(), zahl(), zahl());
          final schritte = math.max(4, ((bis - von).abs() / 6).ceil());
          for (var s = 0; s <= schritte; s++) {
            final w = (von + (bis - von) * s / schritte) * math.pi / 180;
            punkte.add((cx + rx * math.cos(w), cy + ry * math.sin(w)));
          }
      }
    }
    if (punkte.isNotEmpty) striche.add(_Strich(punkte));
  }
  return striche;
}

/// Breite eines Zeichens in Einheiten der Lineatur.
double zeichenBreite(String zeichen) => _glyphen[zeichen]!.$1;

bool kannSchreiben(String zeichen) => _glyphen.containsKey(zeichen);

/// Die Zeichen, die auf dem Blatt geübt werden, in Zeilenreihenfolge.
/// Zu wenige Zeichen werden wiederholt, bis die Seite voll ist.
List<String> schreibZeilen(List<String> buchstaben, SchreibForm form) {
  final zeichen = <String>[
    for (final b in sortiereBuchstaben(buchstaben.where(alleBuchstaben.contains))) ...[
      // ß gibt es nur klein.
      if (form != SchreibForm.klein && b != 'ß') b.toUpperCase(),
      if (form != SchreibForm.gross || b == 'ß') b,
    ],
  ];
  if (zeichen.isEmpty) return [];
  final anzahl = (zeichen.length / schreibZeilenProSeite).ceil() * schreibZeilenProSeite;
  return [for (var i = 0; i < anzahl; i++) zeichen[i % zeichen.length]];
}

class _Farben {
  static final linie = PdfColor.fromHex('#B0BEC5');
  static final mittellinie = PdfColor.fromHex('#90A4AE');
  static final band = PdfColor.fromHex('#E3F2FD');
  static final grundlinie = PdfColor.fromHex('#42A5F5');
  static final nachfahren = PdfColor.fromHex('#78909C');
  static final start = PdfColor.fromHex('#06D6A0');
  static final stern = PdfColor.fromHex('#F4A261');
}

/// Ein Zeichen an Position (x, Grundlinie) mit Einheit u zeichnen.
void _zeichen(
  PdfGraphics g,
  String zeichen,
  double x,
  double y,
  double u, {
  required bool vorlage,
}) {
  final farbe = vorlage ? BlattFarben.text : _Farben.nachfahren;
  g
    ..setLineCap(PdfLineCap.round)
    ..setLineJoin(PdfLineJoin.round)
    ..setStrokeColor(farbe)
    ..setFillColor(farbe)
    ..setLineWidth(u * (vorlage ? 0.13 : 0.09))
    ..setLineDashPattern(vorlage ? [] : [u * 0.2, u * 0.16]);
  final striche = _striche(_glyphen[zeichen]!.$2);
  for (final s in striche) {
    final punkte = [for (final (px, py) in s.punkte) (x + px * u, y + py * u)];
    if (s.istPunkt) {
      g.drawEllipse(punkte.first.$1, punkte.first.$2, u * 0.08, u * 0.08);
      g.fillPath();
      continue;
    }
    g.moveTo(punkte.first.$1, punkte.first.$2);
    for (final p in punkte.skip(1)) {
      g.lineTo(p.$1, p.$2);
    }
    g.strokePath();
  }
  g.setLineDashPattern();
  if (vorlage) {
    // Grüne Startpunkte zeigen, wo jeder Strich beginnt.
    g.setFillColor(_Farben.start);
    for (final s in striche.where((s) => !s.istPunkt)) {
      g.drawEllipse(x + s.punkte.first.$1 * u, y + s.punkte.first.$2 * u, u * 0.1, u * 0.1);
      g.fillPath();
    }
  }
}

/// Eine Zeile mit Hilfslinien: Oberlinie, Mittellinie, Grundlinie,
/// Unterlinie; das Band zwischen Grund- und Mittellinie ist eingefärbt.
void _lineatur(PdfGraphics g, double x0, double x1, double grund, double u) {
  g.setFillColor(_Farben.band);
  g.drawRect(x0, grund, x1 - x0, u);
  g.fillPath();
  void linie(double y, PdfColor farbe, double dicke) {
    g
      ..setStrokeColor(farbe)
      ..setLineWidth(dicke)
      ..moveTo(x0, y)
      ..lineTo(x1, y)
      ..strokePath();
  }

  linie(grund + 2 * u, _Farben.linie, 0.6);
  linie(grund + u, _Farben.mittellinie, 0.6);
  linie(grund, _Farben.grundlinie, 1.1);
  linie(grund - u, _Farben.linie, 0.6);
}

/// Erstellt das Schreibblatt (eine Seite je 10 Zeilen).
Future<Uint8List> erstelleSchreibPdf(
  List<String> buchstaben,
  SchreibForm form,
  ByteData schrift,
  ByteData schriftFett,
) {
  final zeilen = schreibZeilen(buchstaben, form);
  final doc = PdfDocument();
  final sortiert = sortiereBuchstaben(buchstaben);
  PdfInfo(
    doc,
    title: 'Mein Schreibblatt – ${sortiert.map((b) => b.toUpperCase()).join(' ')}',
    creator: 'Lernapp',
  );
  final normal = PdfTtfFont(doc, schrift), fett = PdfTtfFont(doc, schriftFett);
  final format = PdfPageFormat.a4;
  final breite = format.width, hoehe = format.height;
  const rand = 13 * mm, sternBreite = 12 * mm;

  for (var seite = 0; seite * schreibZeilenProSeite < zeilen.length; seite++) {
    final z = Zeichner(PdfPage(doc, pageFormat: format).getGraphics(), normal, fett);
    final y = zeichneKopf(
      z,
      sortiert,
      breite,
      hoehe,
      rand,
      titel: 'Mein Schreibblatt',
      label: 'Diese Buchstaben übe ich:',
      hinweis: 'Fahre die grauen Buchstaben nach. Dann schreibe die Zeile allein fertig!',
    );
    final hoeheZeile = (y - rand - 4 * mm) / schreibZeilenProSeite;
    // Drei Bänder plus Abstand zur nächsten Zeile.
    final u = math.min(7 * mm, hoeheZeile / 4.2);
    final x1 = breite - rand - sternBreite;

    for (var i = 0; i < schreibZeilenProSeite; i++) {
      final zeichen = zeilen[seite * schreibZeilenProSeite + i];
      final oben = y - i * hoeheZeile - 0.9 * u;
      final grund = oben - 2 * u;
      _lineatur(z.g, rand, x1, grund, u);

      final w = zeichenBreite(zeichen) * u;
      var x = rand + 0.6 * u;
      for (var k = 0; k < 3; k++) {
        _zeichen(z.g, zeichen, x, grund, u, vorlage: k == 0);
        x += w + 1.1 * u;
      }

      z.g
        ..setStrokeColor(_Farben.stern)
        ..setLineWidth(1.3);
      z.stern(breite - rand - sternBreite / 2, grund + 0.5 * u, 4.2 * mm);
    }

    z.textRechts(
      'Grüne Punkte zeigen, wo du anfängst.',
      breite - rand,
      rand - 6 * mm + 4,
      8,
      BlattFarben.linie,
    );
  }
  return doc.save();
}
