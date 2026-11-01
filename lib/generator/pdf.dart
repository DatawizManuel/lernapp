/// Zeichnet ein Leseblatt als A4-PDF im kindgerechten Design:
/// Lernapp-Schrift (Andika mit Schul-l), Silbenbögen, Sterne zum Anmalen, Name/Datum-Feld und
/// bunte Kacheln mit den gelernten Buchstaben.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'inhalt.dart';

const mm = PdfPageFormat.mm;

class BlattFarben {
  static final text = PdfColor.fromHex('#2B2D42');
  static final bogen = PdfColor.fromHex('#E76F51');
  static final silbenBand = PdfColor.fromHex('#E3F2FD');
  static final silbenAkzent = PdfColor.fromHex('#42A5F5');
  static final woerterBand = PdfColor.fromHex('#FFF6D9');
  static final woerterAkzent = PdfColor.fromHex('#F4A261');
  static final linie = PdfColor.fromHex('#B0BEC5');
  static const weiss = PdfColors.white;
  static final kacheln = [
    '#EF476F', '#F78C6B', '#FFD166', '#06D6A0', '#118AB2', //
    '#8E7DBE', '#F15BB5', '#00BBF9', '#9BC53D',
  ].map(PdfColor.fromHex).toList();
}

class Zeichner {
  Zeichner(this.g, this.normal, this.fett);

  final PdfGraphics g;
  final PdfFont normal;
  final PdfFont fett;

  double breite(String s, double groesse, {bool istFett = false}) =>
      s.isEmpty ? 0 : (istFett ? fett : normal).stringMetrics(s).advanceWidth * groesse;

  void text(String s, double x, double y, double groesse, PdfColor farbe, {bool istFett = false}) {
    g.setFillColor(farbe);
    g.drawString(istFett ? fett : normal, groesse, s, x, y);
  }

  void textMitte(
    String s,
    double cx,
    double y,
    double groesse,
    PdfColor farbe, {
    bool istFett = false,
  }) => text(s, cx - breite(s, groesse, istFett: istFett) / 2, y, groesse, farbe, istFett: istFett);

  void textRechts(String s, double x, double y, double groesse, PdfColor farbe) =>
      text(s, x - breite(s, groesse), y, groesse, farbe);

  void rundesRechteck(double x, double y, double w, double h, double r, PdfColor farbe) {
    g.setFillColor(farbe);
    g.drawRRect(x, y, w, h, r, r);
    g.fillPath();
  }

  void linie(double x1, double y1, double x2, double y2) {
    g.moveTo(x1, y1);
    g.lineTo(x2, y2);
    g.strokePath();
  }

  void stern(double cx, double cy, double r) {
    for (var i = 0; i < 10; i++) {
      final winkel = math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r : r * 0.45;
      final x = cx + rad * math.cos(winkel), y = cy + rad * math.sin(winkel);
      i == 0 ? g.moveTo(x, y) : g.lineTo(x, y);
    }
    g.closePath();
    g.strokePath();
  }

  /// Untere Hälfte einer Ellipse zwischen x0 und x1 (Silbenbogen).
  void bogen(double x0, double x1, double y, double tiefe) {
    const k = 0.5523;
    final cx = (x0 + x1) / 2, rx = (x1 - x0) / 2;
    g.moveTo(x0, y);
    g.curveTo(x0, y - k * tiefe, cx - k * rx, y - tiefe, cx, y - tiefe);
    g.curveTo(cx + k * rx, y - tiefe, x1, y - k * tiefe, x1, y);
    g.strokePath();
  }

  /// Wort zentriert schreiben und unter jede Silbe einen Silbenbogen setzen.
  void wortMitBoegen(String eintrag, double cx, double grundlinie, double groesse) {
    final silben = eintrag.split('-');
    var x = cx - breite(silben.join(), groesse) / 2;
    text(silben.join(), x, grundlinie, groesse, BlattFarben.text);

    g.setStrokeColor(BlattFarben.bogen);
    g.setLineWidth(1.4);
    final tiefe = groesse * 0.28;
    final oben = grundlinie - groesse * 0.12;
    for (final s in silben) {
      final b = breite(s, groesse);
      final rand = math.min(2.0, b * 0.08);
      bogen(x + rand, x + b - rand, oben, tiefe);
      x += b;
    }
  }
}

/// Text einer Kachel: Buchstaben groß und klein ("Aa"), alles andere
/// (ß, Ziffern, Rechenzeichen) so wie es ist.
String kachelText(String b) => b == 'ß' || b.toUpperCase() == b ? b : b.toUpperCase() + b;

/// Kopfbereich (Titel, Name/Datum, Buchstabenkacheln) zeichnen; gibt die y-Position darunter zurück.
double zeichneKopf(
  Zeichner z,
  List<String> buchstaben,
  double breite,
  double hoehe,
  double rand, {
  String titel = 'Mein Leseblatt',
  String label = 'Diese Buchstaben kann ich schon:',
  String hinweis = 'Lies jede Reihe laut vor. Geschafft? Dann male den Stern an!',
}) {
  final oben = hoehe - rand;
  z.text(titel, rand, oben - 24, 26, BlattFarben.text, istFett: true);

  // Name / Datum
  z.g.setStrokeColor(BlattFarben.linie);
  z.g.setLineWidth(0.8);
  final x0 = breite - rand - 85 * mm;
  z.text('Name:', x0, oben - 10, 12, BlattFarben.text);
  z.linie(x0 + 14 * mm, oben - 12, breite - rand, oben - 12);
  z.text('Datum:', x0, oben - 28, 12, BlattFarben.text);
  z.linie(x0 + 14 * mm, oben - 30, breite - rand, oben - 30);

  // gelernte Buchstaben als bunte Kacheln, bei vielen Buchstaben umgebrochen
  var y = oben - 58;
  z.text(label, rand, y + 6, 13, BlattFarben.text);
  final xStart = rand + z.breite(label, 13) + 4 * mm;
  const kachel = 10.5 * mm, abstand = 1.6 * mm;
  var x = xStart;
  for (var i = 0; i < buchstaben.length; i++) {
    if (x + kachel > breite - rand) {
      x = xStart;
      y -= kachel * 0.82 + 2 * mm;
    }
    final farbe = i % BlattFarben.kacheln.length;
    z.rundesRechteck(x, y - 3, kachel, kachel * 0.82, 4, BlattFarben.kacheln[farbe]);
    z.textMitte(
      kachelText(buchstaben[i]),
      x + kachel / 2,
      y + 3,
      15,
      farbe == 2 ? BlattFarben.text : BlattFarben.weiss,
      istFett: true,
    );
    x += kachel + abstand;
  }

  z.text(hinweis, rand, y - 22, 11.5, BlattFarben.text);
  return y - 30;
}

void _reihen(
  Zeichner z,
  List<List<String>> reihen,
  int nummerStart,
  double x,
  double yOben,
  double breite,
  double reihenHoehe,
  PdfColor band,
  PdfColor akzent,
) {
  const nummerBreite = 10 * mm, sternBreite = 12 * mm;
  final innen = breite - nummerBreite - sternBreite - 2 * mm;
  const minLuecke = 4 * mm;
  for (var i = 0; i < reihen.length; i++) {
    final reihe = reihen[i];
    final y = yOben - (i + 1) * reihenHoehe;
    z.rundesRechteck(x, y + 1.2, breite, reihenHoehe - 2.4, 7, band);

    // Reihennummer
    final cy = y + reihenHoehe / 2;
    z.g.setFillColor(akzent);
    z.g.drawEllipse(x + nummerBreite / 2 + 1, cy, 3.6 * mm, 3.6 * mm);
    z.g.fillPath();
    z.textMitte(
      '${nummerStart + i}',
      x + nummerBreite / 2 + 1,
      cy - 4,
      12,
      BlattFarben.weiss,
      istFett: true,
    );

    // Größte Schrift (max. 27 pt), bei der die ganze Reihe Platz hat;
    // die Wörter werden dann mit gleichen Abständen verteilt.
    final texte = reihe.map((e) => e.replaceAll('-', '')).toList();
    final einheit = texte.fold<double>(0, (s, t) => s + z.breite(t, 1));
    final groesse = math.min(27.0, (innen - minLuecke * reihe.length) / einheit);
    final luecke = (innen - einheit * groesse) / reihe.length;
    final grundlinie = cy - groesse * 0.22;
    var wx = x + nummerBreite + 1 * mm + luecke / 2;
    for (var j = 0; j < reihe.length; j++) {
      final w = z.breite(texte[j], groesse);
      z.wortMitBoegen(reihe[j], wx + w / 2, grundlinie, groesse);
      wx += w + luecke;
    }

    z.g.setStrokeColor(akzent);
    z.g.setLineWidth(1.3);
    z.stern(x + breite - sternBreite / 2, cy, 4.2 * mm);
  }
}

/// Erstellt das PDF. Die Schriften (regular/bold) werden als
/// TTF-Daten übergeben, damit der Generator auch ohne Flutter testbar ist.
Future<Uint8List> erstellePdf(LernblattInhalt inhalt, ByteData schrift, ByteData schriftFett) {
  final doc = PdfDocument();
  PdfInfo(
    doc,
    title: 'Mein Leseblatt – ${inhalt.buchstaben.map((b) => b.toUpperCase()).join(' ')}',
    creator: 'Lernapp',
  );
  final format = PdfPageFormat.a4;
  final page = PdfPage(doc, pageFormat: format);
  final z = Zeichner(page.getGraphics(), PdfTtfFont(doc, schrift), PdfTtfFont(doc, schriftFett));

  final breite = format.width, hoehe = format.height;
  const rand = 13 * mm;
  var y = zeichneKopf(z, inhalt.buchstaben, breite, hoehe, rand);
  const titelHoehe = 8 * mm;
  final platz = y - rand - 6 * mm - titelHoehe * 2;
  final anzahl = math.max(1, inhalt.silben.length + inhalt.woerter.length);
  final reihenHoehe = math.min(23 * mm, platz / anzahl);

  if (inhalt.silben.isNotEmpty) {
    y -= titelHoehe;
    z.text('Silben lesen', rand, y + 5, 13, BlattFarben.silbenAkzent, istFett: true);
    _reihen(
      z,
      inhalt.silben,
      1,
      rand,
      y,
      breite - 2 * rand,
      reihenHoehe,
      BlattFarben.silbenBand,
      BlattFarben.silbenAkzent,
    );
    y -= inhalt.silben.length * reihenHoehe;
  }
  if (inhalt.woerter.isNotEmpty) {
    y -= titelHoehe;
    z.text('Wörter lesen', rand, y + 5, 13, BlattFarben.woerterAkzent, istFett: true);
    _reihen(
      z,
      inhalt.woerter,
      inhalt.silben.length + 1,
      rand,
      y,
      breite - 2 * rand,
      reihenHoehe,
      BlattFarben.woerterBand,
      BlattFarben.woerterAkzent,
    );
  }

  const fussY = rand - 6 * mm + 4;
  z.textRechts('Die Bögen zeigen die Silben.', breite - rand, fussY, 8, BlattFarben.linie);
  if (inhalt.ausschluesse.isNotEmpty) {
    z.text('Ohne: ${inhalt.ausschluesse.join(', ')}', rand, fussY, 8, BlattFarben.linie);
  }
  return doc.save();
}
