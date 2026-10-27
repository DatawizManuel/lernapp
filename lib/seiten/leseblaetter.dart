import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../daten/speicher.dart';
import '../generator/inhalt.dart';
import '../generator/pdf.dart';
import 'profile.dart';
import 'vorschau.dart';

class LeseblaetterSeite extends StatelessWidget {
  const LeseblaetterSeite({super.key, required this.daten});

  final AppDaten daten;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: daten,
      builder: (context, _) {
        final profil = daten.aktivesProfil;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Leseblätter'),
              actions: [
                if (profil != null) _ProfilWahl(daten: daten, profil: profil),
                IconButton(
                  tooltip: 'Kinder verwalten',
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ProfileSeite(daten: daten))),
                ),
              ],
              bottom: profil == null
                  ? null
                  : const TabBar(tabs: [Tab(text: 'Neues Blatt'), Tab(text: 'Gespeichert')]),
            ),
            body: profil == null
                ? _KeinProfil(daten: daten)
                : TabBarView(children: [
                    _NeuesBlatt(key: ValueKey(profil.id), daten: daten, profil: profil),
                    _Gespeichert(daten: daten, profil: profil),
                  ]),
          ),
        );
      },
    );
  }
}

class _ProfilWahl extends StatelessWidget {
  const _ProfilWahl({required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Profil>(
      tooltip: 'Kind wechseln',
      onSelected: daten.waehleProfil,
      itemBuilder: (_) => [
        for (final p in daten.profile)
          CheckedPopupMenuItem(value: p, checked: p.id == profil.id, child: Text(p.name)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          const Icon(Icons.child_care_outlined),
          const SizedBox(width: 4),
          Text(profil.name),
          const Icon(Icons.arrow_drop_down),
        ]),
      ),
    );
  }
}

class _KeinProfil extends StatelessWidget {
  const _KeinProfil({required this.daten});

  final AppDaten daten;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.child_care_outlined, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Lege zuerst ein Profil für dein Kind an. Darin merkt sich die App, '
            'welche Buchstaben es schon kann.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Kind hinzufügen'),
            onPressed: () => kindHinzufuegen(context, daten),
          ),
        ]),
      ),
    );
  }
}

class _NeuesBlatt extends StatefulWidget {
  const _NeuesBlatt({super.key, required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  @override
  State<_NeuesBlatt> createState() => _NeuesBlattState();
}

class _NeuesBlattState extends State<_NeuesBlatt> {
  late final _freiController = TextEditingController(text: widget.profil.freiOhne);
  var _erstelltGerade = false;

  Profil get p => widget.profil;

  @override
  void dispose() {
    _freiController.dispose();
    super.dispose();
  }

  void _aendern(VoidCallback aenderung) {
    setState(aenderung);
    widget.daten.profilGeaendert();
  }

  bool get _hatVokal => p.buchstaben.any(vokale.contains);
  bool get _hatMitlaut => p.buchstaben.any((b) => !(vokale + umlaute).contains(b) && b != 'ß');

  Future<void> _erstellen() async {
    setState(() => _erstelltGerade = true);
    try {
      final inhalt = erzeugeInhalt(p.buchstaben, ohne: p.ohne, freiOhne: p.freiOhne);
      final pdf = await erstellePdf(
        inhalt,
        await rootBundle.load('assets/fonts/Andika-Regular.ttf'),
        await rootBundle.load('assets/fonts/Andika-Bold.ttf'),
      );
      final blatt = await widget.daten.speichereBlatt(p, inhalt, pdf);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VorschauSeite(daten: widget.daten, blatt: blatt, neu: true)));
    } finally {
      if (mounted) setState(() => _erstelltGerade = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final regeln = AusschlussRegeln(p.ohne, frei: p.freiOhne);
    final anzahlWoerter = passendeWoerter(p.buchstaben.toSet(), regeln).length;
    final bereit = _hatVokal && _hatMitlaut;

    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Welche Buchstaben kann ${p.name} schon?', style: text.titleMedium),
          const SizedBox(height: 4),
          const Text('Antippen zum Auswählen. Gilt für groß und klein.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in alleBuchstaben)
              FilterChip(
                label: Text(b == 'ß' ? 'ß' : '${b.toUpperCase()}$b',
                    style: const TextStyle(fontSize: 16)),
                selected: p.buchstaben.contains(b),
                onSelected: (an) => _aendern(() {
                  an ? p.buchstaben.add(b) : p.buchstaben.remove(b);
                  p.buchstaben = sortiereBuchstaben(p.buchstaben);
                }),
              ),
          ]),
          if (p.buchstaben.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _aendern(() => p.buchstaben = []),
                child: const Text('Alle abwählen'),
              ),
            ),
          const Divider(height: 32),
          Text('Was soll noch nicht vorkommen?', style: text.titleMedium),
          const SizedBox(height: 4),
          const Text('Angehakte Kombinationen werden weggelassen, '
              'damit das Blatt zum Leseniveau passt.'),
          for (final bereich in {for (final a in ausschluesse) a.bereich}) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(bereich, style: text.labelLarge),
            ),
            for (final a in ausschluesse.where((a) => a.bereich == bereich))
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(a.name),
                subtitle: Text('z. B. ${a.beispiel}'),
                value: p.ohne.contains(a.kuerzel),
                onChanged: (an) =>
                    _aendern(() => an == true ? p.ohne.add(a.kuerzel) : p.ohne.remove(a.kuerzel)),
              ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _freiController,
            decoration: const InputDecoration(
              labelText: 'Weitere Buchstabenfolgen weglassen',
              hintText: 'z. B. ll, rr',
              border: OutlineInputBorder(),
            ),
            onChanged: (wert) => _aendern(() => p.freiOhne = wert),
          ),
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              bereit
                  ? 'Passende Wörter: $anzahlWoerter'
                      '${anzahlWoerter < 6 ? ' (fehlende Reihen werden mit Silben aufgefüllt)' : ''}'
                  : 'Wähle mindestens einen Selbstlaut (A, E, I, O, U) und einen Mitlaut.',
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _erstelltGerade
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.description_outlined),
                label: const Text('Leseblatt erstellen'),
                onPressed: bereit && !_erstelltGerade ? _erstellen : null,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Gespeichert extends StatelessWidget {
  const _Gespeichert({required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  Future<void> _loeschen(BuildContext context, GespeichertesBlatt b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blatt löschen?'),
        content: Text('Leseblatt vom ${datumText(b.erstellt)} wird gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await daten.loescheBlatt(b);
  }

  @override
  Widget build(BuildContext context) {
    final liste = daten.blaetterVon(profil);
    if (liste.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Für ${profil.name} wurden noch keine Leseblätter erstellt.',
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      itemCount: liste.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final b = liste[i];
        return ListTile(
          leading: const Icon(Icons.picture_as_pdf_outlined),
          title: Text(datumText(b.erstellt)),
          subtitle: Text([
            'Buchstaben: ${b.buchstaben.map((x) => x.toUpperCase()).join(' ')}',
            if (b.ohne.isNotEmpty) 'Ohne: ${b.ohne.join(', ')}',
          ].join('\n')),
          isThreeLine: b.ohne.isNotEmpty,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VorschauSeite(daten: daten, blatt: b))),
          trailing: PopupMenuButton<String>(
            onSelected: (aktion) async {
              final datei = daten.dateiVon(b);
              switch (aktion) {
                case 'drucken':
                  final bytes = await datei.readAsBytes();
                  await Printing.layoutPdf(onLayout: (_) => bytes, name: b.datei);
                case 'teilen':
                  await Printing.sharePdf(bytes: await datei.readAsBytes(), filename: b.datei);
                case 'loeschen':
                  if (context.mounted) await _loeschen(context, b);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'drucken', child: Text('Drucken')),
              PopupMenuItem(value: 'teilen', child: Text('Teilen')),
              PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
            ],
          ),
        );
      },
    );
  }
}
