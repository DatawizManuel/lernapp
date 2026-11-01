// ignore_for_file: avoid_print
// Erzeugt ein Beispiel-Schreibblatt ohne App:
//   dart run tool/schreibblatt.dart a,m,l ausgabe.pdf [beide|gross|klein]
import 'dart:io';
import 'dart:typed_data';

import 'package:lernapp/generator/schreiben.dart';

Future<void> main(List<String> args) async {
  final buchstaben = args[0].toLowerCase().split(',');
  final form = SchreibForm.values.byName(args.length > 2 ? args[2] : 'beide');
  ByteData schrift(String n) => ByteData.sublistView(File('assets/fonts/$n').readAsBytesSync());
  final pdf = await erstelleSchreibPdf(
    buchstaben,
    form,
    schrift('LernappSchrift-Regular.ttf'),
    schrift('LernappSchrift-Bold.ttf'),
  );
  File(args[1]).writeAsBytesSync(pdf);
  print(schreibZeilen(buchstaben, form).join(' '));
}
