import 'package:flutter/material.dart';

import '../daten/speicher.dart';
import 'deutsch.dart';

/// Großer Menüpunkt, wie er auf Start- und Fachseite verwendet wird.
class MenuePunkt extends StatelessWidget {
  const MenuePunkt({
    super.key,
    required this.titel,
    required this.untertitel,
    required this.icon,
    this.onTap,
  });

  final String titel;
  final String untertitel;
  final IconData icon;

  /// `null` = noch nicht verfügbar (ausgegraut).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aktiv = onTap != null;
    final farben = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: aktiv ? farben.secondaryContainer : farben.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: aktiv ? farben.onSecondaryContainer : farben.outline),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titel,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: aktiv ? farben.onSecondaryContainer : farben.outline)),
                    const SizedBox(height: 4),
                    Text(untertitel,
                        style: TextStyle(
                            color: aktiv ? farben.onSecondaryContainer : farben.outline)),
                  ],
                ),
              ),
              if (aktiv) Icon(Icons.chevron_right, color: farben.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class StartSeite extends StatelessWidget {
  const StartSeite({super.key, required this.daten});

  final AppDaten daten;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lernapp')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MenuePunkt(
            titel: 'Deutsch',
            untertitel: 'Leseblätter erstellen',
            icon: Icons.menu_book_outlined,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => DeutschSeite(daten: daten))),
          ),
          const SizedBox(height: 12),
          const MenuePunkt(
            titel: 'Mathe',
            untertitel: 'Kommt bald',
            icon: Icons.calculate_outlined,
          ),
        ],
      ),
    );
  }
}
