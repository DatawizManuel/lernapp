/// Leseblatt mit Wörtern und kurzen Sätzen aus bereits gelernten Buchstaben.
///
/// Oben stehen einige Reihen mit Wörtern (zum Einlesen), darunter kurze
/// Sätze, von leicht nach schwer. Gibt es nur wenige passende Sätze, füllen
/// zusätzliche Wortreihen das Blatt auf.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'inhalt.dart';
import 'pdf.dart';
import 'saetze_liste.dart';

/// Reihen auf dem Blatt insgesamt (Wortreihen + Sätze).
const satzblattReihen = 10;
const satzblattSaetzeMax = 7;
const _satzzeichen = ',.!?';

/// Ein Wort eines Satzes mit dem Satzzeichen dahinter (z. B. "Mi-a" + ",").
typedef SatzWort = ({String wort, String zeichen});

List<SatzWort> zerlegeSatz(String satz) => [
  for (final t in satz.split(' '))
    if (t.isNotEmpty)
      () {
        var i = t.length;
        while (i > 0 && _satzzeichen.contains(t[i - 1])) {
          i--;
        }
        return (wort: t.substring(0, i), zeichen: t.substring(i));
      }(),
];

bool satzErlaubt(String satz, Set<String> erlaubt, AusschlussRegeln regeln) =>
    zerlegeSatz(satz).every((w) => w.wort.isEmpty || wortErlaubt(w.wort, erlaubt, regeln));

double satzSchwierigkeit(String satz) =>
    zerlegeSatz(satz).fold(0.0, (s, w) => s + schwierigkeit(w.wort) + 1);

/// Alle passenden Sätze, sortiert von leicht nach schwer.
List<String> passendeSaetze(Set<String> erlaubt, AusschlussRegeln regeln) =>
    saetze.toSet().where((s) => satzErlaubt(s, erlaubt, regeln)).toList()..sort((a, b) {
      final c = satzSchwierigkeit(a).compareTo(satzSchwierigkeit(b));
      return c != 0 ? c : a.compareTo(b);
    });

class SatzblattInhalt {
  SatzblattInhalt(this.buchstaben, this.woerter, this.saetze, this.ausschluesse);

  final List<String> buchstaben;
  final List<List<String>> woerter;
  final List<String> saetze;
  final List<String> ausschluesse;

  bool get istLeer => woerter.isEmpty && saetze.isEmpty;
}

SatzblattInhalt erzeugeSatzblatt(
  List<String> buchstaben, {
  Iterable<String> ohne = const [],
  String freiOhne = '',
  int? seed,
}) {
  final erlaubt = buchstaben.map((b) => b.toLowerCase()).toSet();
  final rng = math.Random(seed);
  final regeln = AusschlussRegeln(ohne, frei: freiOhne);

  // Aus gleich großen Schwierigkeits-Stufen je einen Satz ziehen.
  final passend = passendeSaetze(erlaubt, regeln);
  final anzahl = math.min(satzblattSaetzeMax, passend.length);
  final gewaehlt = <String>[];
  for (var i = 0; i < anzahl; i++) {
    final stufe = passend.sublist(
      (i * passend.length / anzahl).round(),
      ((i + 1) * passend.length / anzahl).round(),
    );
    gewaehlt.add(stufe[rng.nextInt(stufe.length)]);
  }

  final woerter = wortReihen(erlaubt, satzblattReihen - gewaehlt.length, rng, regeln);
  return SatzblattInhalt(sortiereBuchstaben(erlaubt), woerter, gewaehlt, regeln.beschreibungen);
}

class _Farben {
  static final band = PdfColor.fromHex('#EDE7F6');
  static final akzent = PdfColor.fromHex('#7E57C2');
}

void _satzReihen(
  Zeichner z,
  List<String> saetze,
  int nummerStart,
  double x,
  double yOben,
  double breite,
  double reihenHoehe,
) {
  const nummerBreite = 10 * mm, sternBreite = 12 * mm;
  final innen = breite - nummerBreite - sternBreite - 6 * mm;
  for (var i = 0; i < saetze.length; i++) {
    final y = yOben - (i + 1) * reihenHoehe;
    z.rundesRechteck(x, y + 1.2, breite, reihenHoehe - 2.4, 7, _Farben.band);
    final cy = y + reihenHoehe / 2;
    z.g.setFillColor(_Farben.akzent);
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

    final teile = zerlegeSatz(saetze[i]);
    final ohneBindestrich = saetze[i].replaceAll('-', '');
    final groesse = math.min(26.0, innen / z.breite(ohneBindestrich, 1));
    final grundlinie = cy - groesse * 0.22;
    final leer = z.breite(' ', groesse);
    var wx = x + nummerBreite + 4 * mm;
    for (final t in teile) {
      final w = z.breite(t.wort.replaceAll('-', ''), groesse);
      if (t.wort.isNotEmpty) z.wortMitBoegen(t.wort, wx + w / 2, grundlinie, groesse);
      wx += w;
      z.text(t.zeichen, wx, grundlinie, groesse, BlattFarben.text);
      wx += z.breite(t.zeichen, groesse) + leer;
    }

    z.g.setStrokeColor(_Farben.akzent);
    z.g.setLineWidth(1.3);
    z.stern(x + breite - sternBreite / 2, cy, 4.2 * mm);
  }
}

Future<Uint8List> erstelleSatzPdf(SatzblattInhalt inhalt, ByteData schrift, ByteData schriftFett) {
  final doc = PdfDocument();
  PdfInfo(doc, title: 'Mein Leseblatt – Wörter und Sätze', creator: 'Lernapp');
  final format = PdfPageFormat.a4;
  final z = Zeichner(
    PdfPage(doc, pageFormat: format).getGraphics(),
    PdfTtfFont(doc, schrift),
    PdfTtfFont(doc, schriftFett),
  );
  final breite = format.width, hoehe = format.height;
  const rand = 13 * mm;
  var y = zeichneKopf(z, inhalt.buchstaben, breite, hoehe, rand);
  const titelHoehe = 8 * mm;
  final platz = y - rand - 6 * mm - titelHoehe * 2;
  final anzahl = math.max(1, inhalt.woerter.length + inhalt.saetze.length);
  final reihenHoehe = math.min(23 * mm, platz / anzahl);

  if (inhalt.woerter.isNotEmpty) {
    y -= titelHoehe;
    z.text('Wörter lesen', rand, y + 5, 13, BlattFarben.woerterAkzent, istFett: true);
    zeichneReihen(
      z,
      inhalt.woerter,
      1,
      rand,
      y,
      breite - 2 * rand,
      reihenHoehe,
      BlattFarben.woerterBand,
      BlattFarben.woerterAkzent,
    );
    y -= inhalt.woerter.length * reihenHoehe;
  }
  if (inhalt.saetze.isNotEmpty) {
    y -= titelHoehe;
    z.text('Sätze lesen', rand, y + 5, 13, _Farben.akzent, istFett: true);
    _satzReihen(
      z,
      inhalt.saetze,
      inhalt.woerter.length + 1,
      rand,
      y,
      breite - 2 * rand,
      reihenHoehe,
    );
  }

  const fussY = rand - 6 * mm + 4;
  z.textRechts('Die Bögen zeigen die Silben.', breite - rand, fussY, 8, BlattFarben.linie);
  if (inhalt.ausschluesse.isNotEmpty) {
    z.text('Ohne: ${inhalt.ausschluesse.join(', ')}', rand, fussY, 8, BlattFarben.linie);
  }
  return doc.save();
}
