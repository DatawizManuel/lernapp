/// Zeichnet ein Leseblatt als A4-PDF im kindgerechten Design:
/// Andika-Schrift, Silbenbögen, Sterne zum Anmalen, Name/Datum-Feld und
/// bunte Kacheln mit den gelernten Buchstaben.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'inhalt.dart';

const _mm = PdfPageFormat.mm;

class _Farben {
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

class _Zeichner {
  _Zeichner(this.g, this.normal, this.fett);

  final PdfGraphics g;
  final PdfFont normal;
  final PdfFont fett;

  double breite(String s, double groesse, {bool istFett = false}) =>
      s.isEmpty ? 0 : (istFett ? fett : normal).stringMetrics(s).advanceWidth * groesse;

  void text(String s, double x, double y, double groesse, PdfColor farbe, {bool istFett = false}) {
    g.setFillColor(farbe);
    g.drawString(istFett ? fett : normal, groesse, s, x, y);
  }

  void textMitte(String s, double cx, double y, double groesse, PdfColor farbe,
          {bool istFett = false}) =>
      text(s, cx - breite(s, groesse, istFett: istFett) / 2, y, groesse, farbe, istFett: istFett);

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
    text(silben.join(), x, grundlinie, groesse, _Farben.text);

    g.setStrokeColor(_Farben.bogen);
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

String _kachelText(String b) => b == 'ß' ? 'ß' : b.toUpperCase() + b;

/// Kopfbereich zeichnen; gibt die y-Position darunter zurück.
double _kopf(_Zeichner z, List<String> buchstaben, double breite, double hoehe, double rand) {
  final oben = hoehe - rand;
  z.text('Mein Leseblatt', rand, oben - 24, 26, _Farben.text, istFett: true);

  // Name / Datum
  z.g.setStrokeColor(_Farben.linie);
  z.g.setLineWidth(0.8);
  final x0 = breite - rand - 85 * _mm;
  z.text('Name:', x0, oben - 10, 12, _Farben.text);
  z.linie(x0 + 14 * _mm, oben - 12, breite - rand, oben - 12);
  z.text('Datum:', x0, oben - 28, 12, _Farben.text);
  z.linie(x0 + 14 * _mm, oben - 30, breite - rand, oben - 30);

  // gelernte Buchstaben als bunte Kacheln, bei vielen Buchstaben umgebrochen
  var y = oben - 58;
  const label = 'Diese Buchstaben kann ich schon:';
  z.text(label, rand, y + 6, 13, _Farben.text);
  final xStart = rand + z.breite(label, 13) + 4 * _mm;
  const kachel = 10.5 * _mm, abstand = 1.6 * _mm;
  var x = xStart;
  for (var i = 0; i < buchstaben.length; i++) {
    if (x + kachel > breite - rand) {
      x = xStart;
      y -= kachel * 0.82 + 2 * _mm;
    }
    final farbe = i % _Farben.kacheln.length;
    z.rundesRechteck(x, y - 3, kachel, kachel * 0.82, 4, _Farben.kacheln[farbe]);
    z.textMitte(_kachelText(buchstaben[i]), x + kachel / 2, y + 3, 15,
        farbe == 2 ? _Farben.text : _Farben.weiss,
        istFett: true);
    x += kachel + abstand;
  }

  z.text('Lies jede Reihe laut vor. Geschafft? Dann male den Stern an!', rand, y - 22, 11.5,
      _Farben.text);
  return y - 30;
}

void _reihen(_Zeichner z, List<List<String>> reihen, int nummerStart, double x, double yOben,
    double breite, double reihenHoehe, PdfColor band, PdfColor akzent) {
  const nummerBreite = 10 * _mm, sternBreite = 12 * _mm;
  final innen = breite - nummerBreite - sternBreite - 2 * _mm;
  const minLuecke = 4 * _mm;
  for (var i = 0; i < reihen.length; i++) {
    final reihe = reihen[i];
    final y = yOben - (i + 1) * reihenHoehe;
    z.rundesRechteck(x, y + 1.2, breite, reihenHoehe - 2.4, 7, band);

    // Reihennummer
    final cy = y + reihenHoehe / 2;
    z.g.setFillColor(akzent);
    z.g.drawEllipse(x + nummerBreite / 2 + 1, cy, 3.6 * _mm, 3.6 * _mm);
    z.g.fillPath();
    z.textMitte('${nummerStart + i}', x + nummerBreite / 2 + 1, cy - 4, 12, _Farben.weiss,
        istFett: true);

    // Größte Schrift (max. 27 pt), bei der die ganze Reihe Platz hat;
    // die Wörter werden dann mit gleichen Abständen verteilt.
    final texte = reihe.map((e) => e.replaceAll('-', '')).toList();
    final einheit = texte.fold<double>(0, (s, t) => s + z.breite(t, 1));
    final groesse = math.min(27.0, (innen - minLuecke * reihe.length) / einheit);
    final luecke = (innen - einheit * groesse) / reihe.length;
    final grundlinie = cy - groesse * 0.22;
    var wx = x + nummerBreite + 1 * _mm + luecke / 2;
    for (var j = 0; j < reihe.length; j++) {
      final w = z.breite(texte[j], groesse);
      z.wortMitBoegen(reihe[j], wx + w / 2, grundlinie, groesse);
      wx += w + luecke;
    }

    z.g.setStrokeColor(akzent);
    z.g.setLineWidth(1.3);
    z.stern(x + breite - sternBreite / 2, cy, 4.2 * _mm);
  }
}

/// Erstellt das PDF. Die Schriften (Andika regular/bold) werden als
/// TTF-Daten übergeben, damit der Generator auch ohne Flutter testbar ist.
Future<Uint8List> erstellePdf(LernblattInhalt inhalt, ByteData schrift, ByteData schriftFett) {
  final doc = PdfDocument();
  PdfInfo(doc,
      title: 'Mein Leseblatt – ${inhalt.buchstaben.map((b) => b.toUpperCase()).join(' ')}',
      creator: 'Lernapp');
  final format = PdfPageFormat.a4;
  final page = PdfPage(doc, pageFormat: format);
  final z = _Zeichner(page.getGraphics(), PdfTtfFont(doc, schrift), PdfTtfFont(doc, schriftFett));

  final breite = format.width, hoehe = format.height;
  const rand = 13 * _mm;
  var y = _kopf(z, inhalt.buchstaben, breite, hoehe, rand);
  const titelHoehe = 8 * _mm;
  final platz = y - rand - 6 * _mm - titelHoehe * 2;
  final anzahl = math.max(1, inhalt.silben.length + inhalt.woerter.length);
  final reihenHoehe = math.min(23 * _mm, platz / anzahl);

  if (inhalt.silben.isNotEmpty) {
    y -= titelHoehe;
    z.text('Silben lesen', rand, y + 5, 13, _Farben.silbenAkzent, istFett: true);
    _reihen(z, inhalt.silben, 1, rand, y, breite - 2 * rand, reihenHoehe, _Farben.silbenBand,
        _Farben.silbenAkzent);
    y -= inhalt.silben.length * reihenHoehe;
  }
  if (inhalt.woerter.isNotEmpty) {
    y -= titelHoehe;
    z.text('Wörter lesen', rand, y + 5, 13, _Farben.woerterAkzent, istFett: true);
    _reihen(z, inhalt.woerter, inhalt.silben.length + 1, rand, y, breite - 2 * rand, reihenHoehe,
        _Farben.woerterBand, _Farben.woerterAkzent);
  }

  const fussY = rand - 6 * _mm + 4;
  z.textRechts('Die Bögen zeigen die Silben.', breite - rand, fussY, 8, _Farben.linie);
  if (inhalt.ausschluesse.isNotEmpty) {
    z.text('Ohne: ${inhalt.ausschluesse.join(', ')}', rand, fussY, 8, _Farben.linie);
  }
  return doc.save();
}
