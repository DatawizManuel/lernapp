import 'package:flutter/material.dart';

import '../daten/speicher.dart';
import 'blaetter.dart';
import 'start.dart';

class MatheSeite extends StatelessWidget {
  const MatheSeite({super.key, required this.daten});

  final AppDaten daten;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mathe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MenuePunkt(
            titel: 'Zahlen schreiben',
            untertitel: 'Ziffern nachfahren und schreiben üben, mit Hilfslinien',
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlattSeite(daten: daten, art: BlattArt.zahlen),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuePunkt(
            titel: 'Rechenblätter',
            untertitel: 'Plus, Minus, Mal und Geteilt im Zahlenraum deines Kindes',
            icon: Icons.calculate_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlattSeite(daten: daten, art: BlattArt.rechnen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
