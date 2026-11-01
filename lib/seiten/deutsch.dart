import 'package:flutter/material.dart';

import '../daten/speicher.dart';
import 'blaetter.dart';
import 'start.dart';

class DeutschSeite extends StatelessWidget {
  const DeutschSeite({super.key, required this.daten});

  final AppDaten daten;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deutsch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MenuePunkt(
            titel: 'Leseblätter',
            untertitel: 'Silben und Wörter aus den Buchstaben, die dein Kind schon kann',
            icon: Icons.auto_stories_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlattSeite(daten: daten, art: BlattArt.lesen),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuePunkt(
            titel: 'Schreibblätter',
            untertitel: 'Buchstaben nachfahren und schreiben üben, mit Hilfslinien',
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlattSeite(daten: daten, art: BlattArt.schreiben),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
