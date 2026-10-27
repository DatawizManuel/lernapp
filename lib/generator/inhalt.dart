/// Inhalt eines Leseblatts: Silben und Wörter aus bereits gelernten Buchstaben.
///
/// Aufbau (Schwierigkeit steigt Reihe für Reihe):
///   1-2  offene Silben (ma, lo, ...)
///   3    offene Silben mit großem Anfangsbuchstaben (Mo, La, ...)
///   4    Silben mit Vokal am Anfang (am, el, ...)
///   5    geschlossene Silben (mal, sim, ...)
///   6-10 echte Wörter, nach Schwierigkeit sortiert
/// Gibt es zu wenige passende Wörter, füllen zweisilbige Silbenreihen
/// (ma-lo, ...) das Blatt auf.
library;

import 'dart:math';

import 'wortschatz.dart';

const vokale = 'aeiou';
const umlaute = 'äöü';
// Konsonanten, die sich leicht "dehnen" lassen, kommen zuerst.
const _konsonantReihenfolge = 'mlsrnfwhjdbgtkpvzcqxyß';
const _diphthonge = ['ei', 'ai', 'ie', 'au', 'eu', 'äu'];
const proReihe = 6;
const wortReihenMax = 5;

/// Alle Buchstaben, die im Profil ausgewählt werden können.
const alleBuchstaben = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', //
  'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'ä', 'ö', 'ü', 'ß',
];

typedef Pruefer = bool Function(String wort);

/// Treffer nur innerhalb einer Silbe (Mu-se-um hat kein "eu").
Pruefer _jeSilbe(String muster) {
  final regex = RegExp(muster);
  return (wort) => wort.toLowerCase().split('-').any(regex.hasMatch);
}

Pruefer _imWort(String muster) {
  final regex = RegExp(muster);
  return (wort) => regex.hasMatch(wort.toLowerCase().replaceAll('-', ''));
}

class Ausschluss {
  const Ausschluss(this.kuerzel, this.name, this.beispiel, this.bereich, this.pruefe);

  final String kuerzel;
  final String name;
  final String beispiel;
  final String bereich;
  final Pruefer pruefe;
}

/// Ausschließbare Kombinationen, in der Reihenfolge der Anzeige.
final ausschluesse = <Ausschluss>[
  Ausschluss('h', 'stummes h', 'ohne, Kuh', 'Dehnung und Zwielaute', _imWort('[aeiouäöü]h')),
  Ausschluss('ie', 'ie', 'Riese', 'Dehnung und Zwielaute', _jeSilbe('ie')),
  Ausschluss('ei', 'ei', 'Eis', 'Dehnung und Zwielaute', _jeSilbe('ei')),
  Ausschluss('au', 'au', 'Maus', 'Dehnung und Zwielaute', _jeSilbe('au')),
  Ausschluss('eu', 'eu/äu', 'Eule', 'Dehnung und Zwielaute', _jeSilbe('eu|äu')),
  Ausschluss('ai', 'ai', 'Mais', 'Dehnung und Zwielaute', _jeSilbe('ai')),
  Ausschluss('doppelvokal', 'Doppelvokale', 'Meer, Moos', 'Doppelte Buchstaben',
      _imWort(r'([aeiou])\1')),
  Ausschluss('doppelkonsonant', 'Doppelkonsonanten', 'Rolle, Lamm', 'Doppelte Buchstaben',
      _imWort(r'([^aeiouäöü])\1')),
  Ausschluss('ck', 'ck', 'Decke', 'Buchstabenverbindungen', _imWort('ck')),
  Ausschluss('tz', 'tz', 'Katze', 'Buchstabenverbindungen', _imWort('tz')),
  Ausschluss('ch', 'ch', 'ich', 'Buchstabenverbindungen', _imWort('(?<!s)ch')),
  Ausschluss('sch', 'sch', 'Fisch', 'Buchstabenverbindungen', _imWort('sch')),
  Ausschluss('sp-st', 'sp/st am Silbenanfang', 'Stern', 'Buchstabenverbindungen',
      _jeSilbe('^s[pt]')),
  Ausschluss('qu', 'qu', 'Qualle', 'Buchstabenverbindungen', _imWort('qu')),
  Ausschluss('ng-nk', 'ng/nk', 'Ring, Bank', 'Buchstabenverbindungen', _imWort('n[gk]')),
  Ausschluss('umlaute', 'ä, ö, ü', 'Käse', 'Sonstiges', _imWort('[äöü]')),
  Ausschluss('konsonantenfolge', 'zwei Mitlaute hintereinander in einer Silbe', 'Ulme',
      'Sonstiges', _jeSilbe(r'[^aeiouäöü]{2}')),
];

/// Zerlegt eine freie Eingabe wie "ll, rr" in einzelne Buchstabenfolgen.
List<String> freieFolgen(String eingabe) => {
      for (final t in eingabe.toLowerCase().split(RegExp(r'[,;\s]+')))
        if (t.trim().isNotEmpty) t.trim(),
    }.toList();

class AusschlussRegeln {
  AusschlussRegeln(Iterable<String> kuerzel, {String frei = ''}) {
    final gewaehlt = kuerzel.toSet();
    for (final a in ausschluesse) {
      if (gewaehlt.contains(a.kuerzel)) {
        beschreibungen.add(a.name);
        pruefer.add(a.pruefe);
      }
    }
    for (final folge in freieFolgen(frei)) {
      beschreibungen.add(folge);
      pruefer.add(_imWort(RegExp.escape(folge)));
    }
  }

  final beschreibungen = <String>[];
  final pruefer = <Pruefer>[];

  bool trifft(String wort) => pruefer.any((p) => p(wort));
}

bool wortErlaubt(String wort, Set<String> erlaubt, AusschlussRegeln regeln) =>
    wort.replaceAll('-', '').toLowerCase().split('').every(erlaubt.contains) &&
    !regeln.trifft(wort);

/// Grobe Lese-Schwierigkeit: Länge, Silben, Doppellaute, Konsonantenhäufung.
double schwierigkeit(String wort) {
  final rein = wort.replaceAll('-', '').toLowerCase();
  final silben = '-'.allMatches(wort).length + 1;
  var wert = rein.length + 0.75 * (silben - 1);
  for (final d in _diphthonge) {
    wert += d.allMatches(rein).length * 1.5;
  }
  for (var i = 0; i + 1 < rein.length; i++) {
    if (rein[i] == rein[i + 1]) wert += 1.5;
  }
  var folge = 0;
  for (final ch in rein.split('')) {
    if (!(vokale + umlaute).contains(ch)) {
      folge++;
      if (folge >= 2) wert += 1.5;
    } else {
      folge = 0;
    }
  }
  return wert;
}

List<String> _konsonantenSortiert(Set<String> erlaubt) {
  int rang(String k) {
    final i = _konsonantReihenfolge.indexOf(k);
    return i < 0 ? 98 : i;
  }

  final kons = erlaubt.where((b) => b.length == 1 && !(vokale + umlaute).contains(b)).toList()
    ..sort((a, b) {
      final c = rang(a).compareTo(rang(b));
      return c != 0 ? c : a.compareTo(b);
    });
  return kons;
}

String _gross(String s) => s.isEmpty || s[0] == 'ß' ? s : s[0].toUpperCase() + s.substring(1);

/// Bis zu `anzahl` verschiedene Einträge in zufälliger Reihenfolge.
List<String> _ziehe(List<String> kandidaten, int anzahl, Random rng, AusschlussRegeln regeln) {
  final pool = kandidaten
      .toSet()
      .where((k) => !silbenSperre.contains(k.toLowerCase().replaceAll('-', '')) && !regeln.trifft(k))
      .toList()
    ..shuffle(rng);
  return pool.take(anzahl).toList();
}

List<List<String>> silbenReihen(Set<String> erlaubt, Random rng, AusschlussRegeln regeln,
    {int extra = 0}) {
  final vok = vokale.split('').where(erlaubt.contains).toList();
  final kons = _konsonantenSortiert(erlaubt);
  // Kein deutsches Wort beginnt mit ß, also nur als Silbenende verwenden.
  final anlaut = kons.where((k) => k != 'ß').toList();
  if (vok.isEmpty || anlaut.isEmpty) return [];

  final erste = anlaut.take(2).toList();
  final zweite = anlaut.length > 2 ? anlaut.sublist(2) : anlaut;
  List<String> offen(List<String> ks) => [for (final k in ks) for (final v in vok) k + v];
  List<String> zieh(List<String> kandidaten) => _ziehe(kandidaten, proReihe, rng, regeln);
  final geschlossen = [
    for (final a in anlaut)
      for (final v in vok)
        for (final b in kons)
          if (a != b) a + v + b,
  ];

  final reihen = [
    zieh(offen(erste)),
    zieh(offen(zweite)),
    zieh(offen(anlaut)).map(_gross).toList(),
    zieh([for (final v in vok) for (final k in kons) v + k]),
    zieh(geschlossen),
  ];
  // Zusatzreihen, wenn es zu wenige Wörter gibt: zwei Silben verbinden.
  for (var i = 0; i < extra; i++) {
    final zweiteSilbe = i.isEven ? offen(anlaut) : geschlossen;
    final paare = [
      for (final a in offen(anlaut))
        for (final b in zweiteSilbe)
          if (a[0] != b[0]) '$a-$b',
    ];
    final reihe = zieh(paare);
    reihen.add(i >= 2 ? reihe.map(_gross).toList() : reihe);
  }
  return reihen.where((r) => r.isNotEmpty).toList();
}

/// Alle passenden Wörter, sortiert von leicht nach schwer.
List<String> passendeWoerter(Set<String> erlaubt, AusschlussRegeln regeln) =>
    woerter.toSet().where((w) => wortErlaubt(w, erlaubt, regeln)).toList()
      ..sort((a, b) {
        final c = schwierigkeit(a).compareTo(schwierigkeit(b));
        return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
      });

List<List<String>> wortReihen(
    Set<String> erlaubt, int anzahlReihen, Random rng, AusschlussRegeln regeln) {
  final passend = passendeWoerter(erlaubt, regeln);
  if (passend.isEmpty) return [];
  // In gleich große Schwierigkeits-Stufen teilen, aus jeder Stufe ziehen.
  final stufen = min(anzahlReihen, max(1, passend.length ~/ proReihe));
  final groesse = passend.length / stufen;
  return [
    for (var i = 0; i < stufen; i++)
      (passend.sublist((i * groesse).round(), ((i + 1) * groesse).round())..shuffle(rng))
          .take(proReihe)
          .toList()
        ..sort((a, b) => schwierigkeit(a).compareTo(schwierigkeit(b))),
  ];
}

class LernblattInhalt {
  LernblattInhalt(this.buchstaben, this.silben, this.woerter, this.ausschluesse);

  /// Gelernte Buchstaben (klein), in der Reihenfolge der Auswahl.
  final List<String> buchstaben;
  final List<List<String>> silben;
  final List<List<String>> woerter;

  /// Kurze Namen der ausgeschlossenen Kombinationen (für die Fußzeile).
  final List<String> ausschluesse;

  bool get istLeer => silben.isEmpty && woerter.isEmpty;
}

/// Sortiert Buchstaben wie im Alphabet (Umlaute und ß am Ende).
List<String> sortiereBuchstaben(Iterable<String> buchstaben) =>
    buchstaben.toSet().toList()..sort((a, b) => alleBuchstaben.indexOf(a).compareTo(alleBuchstaben.indexOf(b)));

LernblattInhalt erzeugeInhalt(List<String> buchstaben,
    {Iterable<String> ohne = const [], String freiOhne = '', int? seed}) {
  final erlaubt = buchstaben.map((b) => b.toLowerCase()).toSet();
  final rng = Random(seed);
  final regeln = AusschlussRegeln(ohne, frei: freiOhne);
  final w = wortReihen(erlaubt, wortReihenMax, rng, regeln);
  final s = silbenReihen(erlaubt, rng, regeln, extra: wortReihenMax - w.length);
  return LernblattInhalt(sortiereBuchstaben(erlaubt), s, w, regeln.beschreibungen);
}
