// Erzeugt ein Beispiel-Leseblatt ohne App:
//   dart run tool/beispiel.dart a,e,i,o,u,l,s,m,r ausgabe.pdf [ohne-kuerzel,...]
import 'dart:io';
import 'dart:typed_data';

import 'package:lernapp/generator/inhalt.dart';
import 'package:lernapp/generator/pdf.dart';

Future<void> main(List<String> args) async {
  final buchstaben = args[0].toLowerCase().split(',');
  final ohne = args.length > 2 ? args[2].split(',') : <String>[];
  final inhalt = erzeugeInhalt(buchstaben, ohne: ohne, seed: 23);
  for (final (i, r) in [...inhalt.silben, ...inhalt.woerter].indexed) {
    print('${i + 1}: ${r.join('  ')}');
  }
  ByteData schrift(String n) => ByteData.sublistView(File('assets/fonts/$n').readAsBytesSync());
  final pdf = await erstellePdf(inhalt, schrift('Andika-Regular.ttf'), schrift('Andika-Bold.ttf'));
  File(args[1]).writeAsBytesSync(pdf);
}
