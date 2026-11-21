// ignore_for_file: avoid_print
// Prüft die Themenpakete auf Tippfehler in der Silbentrennung:
//   dart run tool/themen_pruefen.dart
import 'package:lernapp/generator/saetze.dart';
import 'package:lernapp/generator/themen/leicht.dart';
import 'package:lernapp/generator/themen/themen.dart';

final _vokal = RegExp('[aeiouäöüy]', caseSensitive: false);
final _gruppen = RegExp(
  '(ei|ai|au|eu|äu|ie|aa|ee|oo|uu|öö+|ea|ou|oy|ui|oi|[aeiouäöüy])',
  caseSensitive: false,
);
// Fremdwörter und Namen, die richtig getrennt sind, obwohl die Prüfung anschlägt.
const _ausnahmen = {
  'Team',
  'Tour',
  'Puuh',
  'Chase',
  'Yo',
  'Ma-ui',
  'Pin-guin',
  'Kaul-quap-pe',
  'quakt',
  'Qual-le',
  'qua-ken',
  'miaut',
  'Ka-ka-o',
  'Son-nen-cre-me',
  'Cow-boy',
  'Yo-shi',
};

List<String> pruefeWort(String w) {
  final f = <String>[];
  if (_ausnahmen.contains(w)) return f;
  if (!RegExp(r'^[A-Za-zÄÖÜäöüß-]+$').hasMatch(w)) f.add('Zeichen');
  for (final s in w.split('-')) {
    if (!_vokal.hasMatch(s)) f.add('Silbe ohne Vokal "$s"');
  }
  final teile = w.split('-');
  for (final s in teile.skip(1)) {
    if (RegExp(r'^([bcdfghjklmnpqrstvwxzß])\1').hasMatch(s)) f.add('Silbe beginnt mit "$s"');
  }
  for (final s in teile) {
    if (_gruppen.allMatches(s.toLowerCase()).length > 1) f.add('Silbe "$s" zu lang?');
  }
  return f;
}

void main() {
  final ids = <String>{};
  for (final k in {...leichteWoerter.keys, ...leichteSaetze.keys}) {
    if (themaMitId(k) == null) print('leicht.dart: unbekanntes Thema $k');
  }
  var fehler = 0;
  for (final t in alleThemen) {
    if (!ids.add(t.id)) print('DOPPELTE ID ${t.id}');
    final woerter = t.woerter;
    for (final w in woerter) {
      for (final f in pruefeWort(w)) {
        print('${t.id}: $w → $f');
        fehler++;
      }
    }
    final saetzeRein = t.saetze.map((x) => x.replaceAll('-', '')).toList();
    if (saetzeRein.toSet().length != saetzeRein.length) print('${t.id}: doppelte Sätze');
    for (final s in t.saetze) {
      if (!RegExp(r'[.!?]$').hasMatch(s)) print('${t.id}: Satzende fehlt: $s');
      for (final teil in zerlegeSatz(s)) {
        for (final f in pruefeWort(teil.wort)) {
          print('${t.id}: "$s" $teil.wort → $f');
          fehler++;
        }
      }
    }
    if (woerter.length < 18 || t.saetze.length < 8) {
      print('${t.id}: nur ${woerter.length} Wörter, ${t.saetze.length} Sätze');
    }
  }
  print('${alleThemen.length} Themen, $fehler Hinweise');
}
