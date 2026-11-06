// ignore_for_file: avoid_print
// Erzeugt Beispielblätter ohne App:
//   dart run tool/lesen.dart saetze a,e,i,o,u,l,s,m,r blatt.pdf [ohne,...]
//   dart run tool/lesen.dart luecken a,e,i,o,u,l,s,m,r blatt.pdf [ohne,...]
//   dart run tool/lesen.dart linien - blatt.pdf
import 'dart:io';
import 'dart:typed_data';

import 'package:lernapp/generator/inhalt.dart';
import 'package:lernapp/generator/luecken.dart';
import 'package:lernapp/generator/saetze.dart';
import 'package:lernapp/generator/schreiben.dart';

Future<void> main(List<String> args) async {
  ByteData schrift(String n) => ByteData.sublistView(File('assets/fonts/$n').readAsBytesSync());
  final normal = schrift('LernappSchrift-Regular.ttf'), fett = schrift('LernappSchrift-Bold.ttf');
  final buchstaben = args[1].toLowerCase().split(',');
  final ohne = args.length > 3 ? args[3].split(',') : <String>[];
  final Uint8List pdf;
  switch (args[0]) {
    case 'saetze':
      final inhalt = erzeugeSatzblatt(buchstaben, ohne: ohne, seed: 7);
      for (final r in inhalt.woerter) {
        print(r.join('  '));
      }
      inhalt.saetze.forEach(print);
      print(
        '(${passendeSaetze(buchstaben.toSet(), AusschlussRegeln(ohne)).length} passende Sätze)',
      );
      pdf = await erstelleSatzPdf(inhalt, normal, fett);
    case 'luecken':
      final aufgaben = erzeugeLueckenwoerter(buchstaben, ohne: ohne, seed: 7);
      aufgaben.forEach(print);
      pdf = await erstelleLueckenPdf(
        buchstaben,
        aufgaben,
        AusschlussRegeln(ohne).beschreibungen,
        normal,
        fett,
      );
    default:
      pdf = await erstelleLinienPdf(normal, fett);
  }
  File(args[2]).writeAsBytesSync(pdf);
}
