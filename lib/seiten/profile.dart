import 'package:flutter/material.dart';

import '../daten/speicher.dart';

Future<String?> _nameAbfragen(BuildContext context, String titel, [String start = '']) {
  final controller = TextEditingController(text: start);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titel),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name des Kindes'),
        onSubmitted: (wert) => Navigator.pop(context, wert),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Speichern')),
      ],
    ),
  );
}

Future<void> kindHinzufuegen(BuildContext context, AppDaten daten) async {
  final name = await _nameAbfragen(context, 'Kind hinzufügen');
  if (name != null && name.trim().isNotEmpty) await daten.neuesProfil(name);
}

class ProfileSeite extends StatelessWidget {
  const ProfileSeite({super.key, required this.daten});

  final AppDaten daten;

  Future<void> _umbenennen(BuildContext context, Profil p) async {
    final name = await _nameAbfragen(context, 'Umbenennen', p.name);
    if (name != null && name.trim().isNotEmpty) {
      p.name = name.trim();
      await daten.profilGeaendert();
    }
  }

  Future<void> _loeschen(BuildContext context, Profil p) async {
    final anzahl = daten.blaetterVon(p).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${p.name} löschen?'),
        content: Text(anzahl == 0
            ? 'Die Einstellungen für dieses Kind werden gelöscht.'
            : 'Die Einstellungen und $anzahl gespeicherte Leseblätter werden gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await daten.loescheProfil(p);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: daten,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Kinder')),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Kind hinzufügen'),
          onPressed: () => kindHinzufuegen(context, daten),
        ),
        body: daten.profile.isEmpty
            ? const Center(child: Text('Noch kein Kind angelegt.'))
            : ListView(children: [
                for (final p in daten.profile)
                  ListTile(
                    leading: Icon(p.id == daten.aktivesProfil?.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
                    title: Text(p.name),
                    subtitle: Text(p.buchstaben.isEmpty
                        ? 'Noch keine Buchstaben ausgewählt'
                        : p.buchstaben.map((b) => b.toUpperCase()).join(' ')),
                    onTap: () => daten.waehleProfil(p),
                    trailing: PopupMenuButton<String>(
                      onSelected: (aktion) => aktion == 'umbenennen'
                          ? _umbenennen(context, p)
                          : _loeschen(context, p),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'umbenennen', child: Text('Umbenennen')),
                        PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
                      ],
                    ),
                  ),
              ]),
      ),
    );
  }
}
