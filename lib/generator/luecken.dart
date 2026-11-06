/// Lückenwörter: In jedem Wort fehlt ein Buchstabe. Darunter stehen drei
/// Buchstaben zur Auswahl; das Kind kreist den richtigen ein und schreibt
/// ihn ins Kästchen.
///
/// Drei Stufen (je 8 Wörter): kurze Wörter mit fehlendem Selbstlaut, dann
/// fehlende Mitlaute, zuletzt längere Wörter mit Lücke an beliebiger Stelle.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'inhalt.dart';
import 'pdf.dart';
import 'saetze.dart';
import 'saetze_liste.dart';
import 'wortschatz.dart';

const lueckenSpalten = 3;
const lueckenZeilen = 8;
const lueckenProSeite = lueckenSpalten * lueckenZeilen;
const _selbstlaute = 'aeiouäöü';

class LueckenWort {
  const LueckenWort(this.wort, this.stelle, this.auswahl);

  /// Das ganze Wort ohne Silbentrennung, z. B. "Mama".
  final String wort;

  /// Position des fehlenden Buchstabens.
  final int stelle;

  /// Buchstaben zur Auswahl (der richtige ist dabei), schon gemischt.
  final List<String> auswahl;

  String get loesung => wort[stelle];
  String get vorne => wort.substring(0, stelle);
  String get hinten => wort.substring(stelle + 1);

  @override
  String toString() => '$vorne _ $hinten  (${auswahl.join(' ')})';
}

/// Alle bekannten Wörter (klein, ohne Silbentrennung), damit keine falsche
/// Auswahl zufällig ein anderes echtes Wort ergibt.
final Set<String> _bekannteWoerter = {
  for (final w in woerter) w.replaceAll('-', '').toLowerCase(),
  for (final s in saetze)
    for (final t in zerlegeSatz(s)) t.wort.replaceAll('-', '').toLowerCase(),
};

bool _istSelbstlaut(String b) => _selbstlaute.contains(b.toLowerCase());

List<String> _auswahl(String wort, int stelle, Set<String> erlaubt, math.Random rng) {
  final richtig = wort[stelle].toLowerCase();
  final gross = wort[stelle] != richtig;
  bool ergibtWort(String b) => _bekannteWoerter.contains(
    (wort.substring(0, stelle) + b + wort.substring(stelle + 1)).toLowerCase(),
  );
  // ß nie am Wortanfang anbieten.
  final moeglich =
      erlaubt.where((b) => b != richtig && !ergibtWort(b) && !(stelle == 0 && b == 'ß')).toList()
        ..shuffle(rng);
  final gleicheArt = moeglich.where((b) => _istSelbstlaut(b) == _istSelbstlaut(richtig));
  final andere = moeglich.where((b) => _istSelbstlaut(b) != _istSelbstlaut(richtig));
  final liste = [
    richtig,
    ...[...gleicheArt, ...andere].take(2),
  ]..shuffle(rng);
  return [for (final b in liste) gross ? b.toUpperCase() : b];
}

List<LueckenWort> erzeugeLueckenwoerter(
  List<String> buchstaben, {
  Iterable<String> ohne = const [],
  String freiOhne = '',
  int anzahl = lueckenProSeite,
  int? seed,
}) {
  final erlaubt = buchstaben.map((b) => b.toLowerCase()).toSet();
  final rng = math.Random(seed);
  final regeln = AusschlussRegeln(ohne, frei: freiOhne);
  // Bei Wörtern mit zwei Buchstaben wäre die Lücke kaum zu lesen.
  final passend = [
    for (final w in passendeWoerter(erlaubt, regeln))
      if (w.replaceAll('-', '').length >= 3) w.replaceAll('-', ''),
  ];
  if (passend.isEmpty) return [];

  const stufen = 3;
  final proStufe = anzahl ~/ stufen;
  final ergebnis = <LueckenWort>[];
  final benutzt = <String>{};
  for (var s = 0; s < stufen; s++) {
    // Wörter der Stufe; bei wenigen Wörtern dürfen sich die Stufen überlappen.
    final von = (s * passend.length / stufen).floor();
    final bis = math.max(von + 1, ((s + 1) * passend.length / stufen).ceil());
    final pool = passend.sublist(math.min(von, passend.length - 1), math.min(bis, passend.length));
    bool passt(String w, int i) => switch (s) {
      0 => _istSelbstlaut(w[i]),
      1 => !_istSelbstlaut(w[i]),
      _ => true,
    };
    var kandidaten = [
      for (final w in pool)
        for (var i = 0; i < w.length; i++)
          if (passt(w, i)) (w, i),
    ];
    if (kandidaten.isEmpty) {
      kandidaten = [
        for (final w in pool)
          for (var i = 0; i < w.length; i++) (w, i),
      ];
    }
    kandidaten.shuffle(rng);
    final gewaehlt = <(String, int)>[];
    final woerterDerStufe = <String>{};
    // Zuerst jedes Wort nur einmal, dann (bei wenigen Wörtern) auch öfter.
    for (final erlaubtDoppelt in [false, true]) {
      for (final k in kandidaten) {
        if (gewaehlt.length >= proStufe) break;
        final schonDa = benutzt.contains('${k.$1}|${k.$2}');
        if (schonDa || (!erlaubtDoppelt && woerterDerStufe.contains(k.$1))) continue;
        gewaehlt.add(k);
        woerterDerStufe.add(k.$1);
        benutzt.add('${k.$1}|${k.$2}');
      }
    }
    gewaehlt.sort((a, b) => schwierigkeit(a.$1).compareTo(schwierigkeit(b.$1)));
    for (final (w, i) in gewaehlt) {
      ergebnis.add(LueckenWort(w, i, _auswahl(w, i, erlaubt, rng)));
    }
  }
  return ergebnis;
}

class _Farben {
  static final band = PdfColor.fromHex('#E0F7FA');
  static final akzent = PdfColor.fromHex('#26A69A');
  static final kaestchen = PdfColor.fromHex('#E76F51');
  static final auswahl = PdfColor.fromHex('#546E7A');
}

Future<Uint8List> erstelleLueckenPdf(
  List<String> buchstaben,
  List<LueckenWort> aufgaben,
  List<String> ausschluesse,
  ByteData schrift,
  ByteData schriftFett,
) {
  final doc = PdfDocument();
  PdfInfo(doc, title: 'Lückenwörter', creator: 'Lernapp');
  final format = PdfPageFormat.a4;
  final z = Zeichner(
    PdfPage(doc, pageFormat: format).getGraphics(),
    PdfTtfFont(doc, schrift),
    PdfTtfFont(doc, schriftFett),
  );
  final breite = format.width, hoehe = format.height;
  const rand = 13 * mm;
  final y = zeichneKopf(
    z,
    sortiereBuchstaben(buchstaben.map((b) => b.toLowerCase())),
    breite,
    hoehe,
    rand,
    titel: 'Lückenwörter',
    hinweis: 'Welcher Buchstabe fehlt? Kreise ihn ein und schreibe ihn ins Kästchen.',
  );

  const sternBreite = 12 * mm;
  final zeilen = (aufgaben.length / lueckenSpalten).ceil();
  final hoeheZeile = math.min(30 * mm, (y - rand - 8 * mm) / lueckenZeilen);
  final spalte = (breite - 2 * rand - sternBreite) / lueckenSpalten;
  final groesse = math.min(26.0, hoeheZeile * 0.36);
  final klein = groesse * 0.62;

  for (var r = 0; r < zeilen; r++) {
    final oben = y - 2 * mm - r * hoeheZeile;
    final unten = oben - hoeheZeile;
    z.rundesRechteck(rand, unten + 1.2, breite - 2 * rand, hoeheZeile - 2.4, 7, _Farben.band);
    final grundlinie = unten + hoeheZeile * 0.52;
    final auswahlLinie = unten + hoeheZeile * 0.17;

    for (var s = 0; s < lueckenSpalten; s++) {
      final n = r * lueckenSpalten + s;
      if (n >= aufgaben.length) break;
      final a = aufgaben[n];
      final cx = rand + (s + 0.5) * spalte;

      // Wort mit Kästchen an der Stelle des fehlenden Buchstabens.
      final kastenBreite = math.max(z.breite('m', groesse), z.breite(a.loesung, groesse)) * 1.15;
      final kastenHoehe = groesse * 0.95;
      final vorneBreite = z.breite(a.vorne, groesse);
      final gesamt = vorneBreite + kastenBreite + z.breite(a.hinten, groesse) + 4;
      var x = cx - gesamt / 2;
      z.text(a.vorne, x, grundlinie, groesse, BlattFarben.text);
      x += vorneBreite + 2;
      final kastenUnten = grundlinie - groesse * 0.2;
      z.rundesRechteck(x, kastenUnten, kastenBreite, kastenHoehe, 4, PdfColors.white);
      z.g
        ..setStrokeColor(_Farben.kaestchen)
        ..setLineWidth(1.2)
        ..setLineDashPattern([3, 2])
        ..drawRRect(x, kastenUnten, kastenBreite, kastenHoehe, 4, 4)
        ..strokePath()
        ..setLineDashPattern();
      x += kastenBreite + 2;
      z.text(a.hinten, x, grundlinie, groesse, BlattFarben.text);

      // Auswahl darunter, mit Platz zum Einkreisen.
      final abstand = klein * 1.6;
      final ax = cx - (a.auswahl.length - 1) * abstand / 2;
      for (var i = 0; i < a.auswahl.length; i++) {
        z.textMitte(a.auswahl[i], ax + i * abstand, auswahlLinie, klein, _Farben.auswahl);
      }
    }

    z.g
      ..setStrokeColor(_Farben.akzent)
      ..setLineWidth(1.3);
    z.stern(breite - rand - sternBreite / 2, (oben + unten) / 2, 4.2 * mm);
  }

  if (ausschluesse.isNotEmpty) {
    z.text('Ohne: ${ausschluesse.join(', ')}', rand, rand - 6 * mm + 4, 8, BlattFarben.linie);
  }
  return doc.save();
}
