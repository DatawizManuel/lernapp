// ignore_for_file: avoid_print
// Erzeugt Beispiel-Mathe-Blätter ohne App:
//   dart run tool/mathe.dart zahlen 1,2,3 ausgabe.pdf
//   dart run tool/mathe.dart rechnen plus,minus 20 ausgabe.pdf
import 'dart:io';
import 'dart:typed_data';

import 'package:lernapp/generator/rechnen.dart';
import 'package:lernapp/generator/schreiben.dart';

Future<void> main(List<String> args) async {
  ByteData schrift(String n) => ByteData.sublistView(File('assets/fonts/$n').readAsBytesSync());
  final (r, b) = (schrift('LernappSchrift-Regular.ttf'), schrift('LernappSchrift-Bold.ttf'));
  if (args[0] == 'zahlen') {
    File(args[2]).writeAsBytesSync(await erstelleZahlenSchreibPdf(args[1].split(','), r, b));
  } else {
    final arten = [for (final n in args[1].split(',')) Rechenart.values.byName(n)];
    final raum = int.parse(args[2]);
    print(erzeugeAufgaben(arten, raum, seed: 7).join('   '));
    File(args[3]).writeAsBytesSync(await erstelleRechenPdf(arten, raum, r, b, seed: 7));
  }
}
