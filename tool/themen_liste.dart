// ignore_for_file: avoid_print
// Gibt alle Themen mit Wörtern und Sätzen als Markdown aus:
//   dart run tool/themen_liste.dart > themen.md
import 'package:lernapp/generator/themen/themen.dart';

void main() {
  print('# Themenpakete (${alleThemen.length} Themen)\n');
  for (final b in themenBereiche) {
    print('## $b\n');
    for (final t in alleThemen.where((t) => t.bereich == b)) {
      print('### ${t.name}\n');
      print('**Wörter:** ${t.woerter.map((w) => w.replaceAll('-', '')).join(', ')}\n');
      print('**Sätze:** ${t.saetze.map((s) => s.replaceAll('-', '')).join(' ')}\n');
    }
  }
}
