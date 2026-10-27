import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'daten/speicher.dart';
import 'seiten/start.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final daten = await AppDaten.laden(await getApplicationDocumentsDirectory());
  runApp(LernApp(daten: daten));
}

class LernApp extends StatelessWidget {
  const LernApp({super.key, required this.daten});

  final AppDaten daten;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lernapp',
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF455A64)),
        useMaterial3: true,
      ),
      home: StartSeite(daten: daten),
    );
  }
}
