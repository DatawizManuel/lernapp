/// Themenpakete für das Blatt „Wörter und Sätze“.
///
/// Jedes Thema hat Wörter und kurze Sätze mit Silbentrennung (Bindestriche).
/// Der Generator nimmt davon nur, was aus den gelernten Buchstaben besteht,
/// und füllt den Rest mit dem allgemeinen Wortschatz auf.
library;

import 'alltag.dart';
import 'fantasie.dart';
import 'figuren.dart';
import 'leicht.dart';
import 'natur.dart';
import 'tiere.dart';

class Thema {
  const Thema(this.id, this.name, this.bereich, this._woerter, this._saetze);

  /// Kurzer, stabiler Schlüssel (wird im Profil gespeichert).
  final String id;
  final String name;
  final String bereich;

  /// Wörter, durch Leerzeichen getrennt.
  final String _woerter;

  /// Sätze, durch "|" getrennt.
  final String _saetze;

  List<String> get woerter => {
    for (final w in '$_woerter ${leichteWoerter[id] ?? ''}'.split(RegExp(r'\s+')))
      if (w.isNotEmpty) w,
  }.toList();
  List<String> get saetze => {
    for (final s in '$_saetze|${leichteSaetze[id] ?? ''}'.split('|'))
      if (s.trim().isNotEmpty) s.trim(),
  }.toList();
}

/// Alle Themen in der Reihenfolge der Anzeige.
final List<Thema> alleThemen = [
  ...themenTiere,
  ...themenFiguren,
  ...themenFantasie,
  ...themenNatur,
  ...themenAlltag,
];

/// Die Bereiche in der Reihenfolge der Anzeige.
List<String> get themenBereiche => {for (final t in alleThemen) t.bereich}.toList();

Thema? themaMitId(String? id) {
  if (id == null) return null;
  for (final t in alleThemen) {
    if (t.id == id) return t;
  }
  return null;
}
