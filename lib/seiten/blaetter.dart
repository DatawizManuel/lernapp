import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../daten/speicher.dart';
import '../generator/inhalt.dart';
import '../generator/pdf.dart';
import '../generator/schreiben.dart';
import 'profile.dart';
import 'vorschau.dart';

/// Seite für eine Blatt-Art (Leseblätter oder Schreibblätter) mit den
/// Tabs „Neues Blatt“ und „Gespeichert“.
class BlattSeite extends StatelessWidget {
  const BlattSeite({super.key, required this.daten, required this.art});

  final AppDaten daten;
  final BlattArt art;

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
              title: Text(art == BlattArt.lesen ? 'Leseblätter' : 'Schreibblätter'),
              actions: [
                if (profil != null) _ProfilWahl(daten: daten, profil: profil),
                IconButton(
                  tooltip: 'Kinder verwalten',
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => ProfileSeite(daten: daten))),
                ),
              ],
              bottom: profil == null
                  ? null
                  : const TabBar(
                      tabs: [
                        Tab(text: 'Neues Blatt'),
                        Tab(text: 'Gespeichert'),
                      ],
                    ),
            ),
            body: profil == null
                ? _KeinProfil(daten: daten)
                : TabBarView(
                    children: [
                      if (art == BlattArt.lesen)
                        _NeuesLeseblatt(key: ValueKey(profil.id), daten: daten, profil: profil)
                      else
                        _NeuesSchreibblatt(key: ValueKey(profil.id), daten: daten, profil: profil),
                      _Gespeichert(daten: daten, profil: profil, art: art),
                    ],
                  ),
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
        child: Row(
          children: [
            const Icon(Icons.child_care_outlined),
            const SizedBox(width: 4),
            Text(profil.name),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
    );
  }
}

/// Auswahl der Buchstaben als Chips (Aa, Bb, …).
class _BuchstabenWahl extends StatelessWidget {
  const _BuchstabenWahl({required this.auswahl, required this.aendern});

  final List<String> auswahl;
  final void Function(List<String> neu) aendern;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in alleBuchstaben)
              FilterChip(
                label: Text(kachelText(b), style: const TextStyle(fontSize: 16)),
                selected: auswahl.contains(b),
                onSelected: (an) => aendern(
                  sortiereBuchstaben(an ? [...auswahl, b] : auswahl.where((x) => x != b)),
                ),
              ),
          ],
        ),
        if (auswahl.isNotEmpty)
          TextButton(onPressed: () => aendern([]), child: const Text('Alle abwählen')),
      ],
    );
  }
}

/// Hinweiszeile und Knopf unten auf dem Tab „Neues Blatt“.
class _ErstellenLeiste extends StatelessWidget {
  const _ErstellenLeiste({
    required this.hinweis,
    required this.knopf,
    required this.laeuft,
    this.onPressed,
  });

  final String hinweis;
  final String knopf;
  final bool laeuft;

  /// `null` = noch nicht bereit.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hinweis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: laeuft
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description_outlined),
                label: Text(knopf),
                onPressed: laeuft ? null : onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<(ByteData, ByteData)> _schriften() async => (
  await rootBundle.load('assets/fonts/LernappSchrift-Regular.ttf'),
  await rootBundle.load('assets/fonts/LernappSchrift-Bold.ttf'),
);

/// Gemeinsamer Ablauf: PDF erzeugen, speichern, Vorschau öffnen.
mixin _Erstellen<T extends StatefulWidget> on State<T> {
  var laeuft = false;

  Future<void> erstellen(AppDaten daten, Future<GespeichertesBlatt> Function() speichern) async {
    setState(() => laeuft = true);
    try {
      final blatt = await speichern();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VorschauSeite(daten: daten, blatt: blatt, neu: true),
        ),
      );
    } finally {
      if (mounted) setState(() => laeuft = false);
    }
  }
}

class _NeuesSchreibblatt extends StatefulWidget {
  const _NeuesSchreibblatt({super.key, required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  @override
  State<_NeuesSchreibblatt> createState() => _NeuesSchreibblattState();
}

class _NeuesSchreibblattState extends State<_NeuesSchreibblatt> with _Erstellen {
  Profil get p => widget.profil;

  void _aendern(VoidCallback aenderung) {
    setState(aenderung);
    widget.daten.profilGeaendert();
  }

  Future<GespeichertesBlatt> _speichern() async {
    final (schrift, fett) = await _schriften();
    final pdf = await erstelleSchreibPdf(p.schreibBuchstaben, p.schreibForm, schrift, fett);
    return widget.daten.speichereBlatt(
      p,
      BlattArt.schreiben,
      pdf,
      buchstaben: sortiereBuchstaben(p.schreibBuchstaben),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final zeilen = schreibZeilen(p.schreibBuchstaben, p.schreibForm).length;
    final seiten = (zeilen / schreibZeilenProSeite).ceil();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welche Buchstaben soll ${p.name} schreiben üben?', style: text.titleMedium),
              const SizedBox(height: 12),
              if (p.buchstaben.isNotEmpty && p.schreibBuchstaben.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.content_copy_outlined),
                    label: const Text('Buchstaben vom Leseblatt übernehmen'),
                    onPressed: () => _aendern(() => p.schreibBuchstaben = [...p.buchstaben]),
                  ),
                ),
              _BuchstabenWahl(
                auswahl: p.schreibBuchstaben,
                aendern: (neu) => _aendern(() => p.schreibBuchstaben = neu),
              ),
              const Divider(height: 32),
              Text('Groß- oder Kleinbuchstaben?', style: text.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<SchreibForm>(
                segments: const [
                  ButtonSegment(value: SchreibForm.beide, label: Text('Beide')),
                  ButtonSegment(value: SchreibForm.gross, label: Text('Nur groß')),
                  ButtonSegment(value: SchreibForm.klein, label: Text('Nur klein')),
                ],
                selected: {p.schreibForm},
                onSelectionChanged: (wahl) => _aendern(() => p.schreibForm = wahl.first),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jede Zeile beginnt mit dem Buchstaben als Vorlage, danach zweimal '
                'strichliert zum Nachfahren. Der Rest der Zeile ist frei zum Üben.',
              ),
            ],
          ),
        ),
        _ErstellenLeiste(
          hinweis: zeilen == 0
              ? 'Wähle mindestens einen Buchstaben.'
              : '$seiten ${seiten == 1 ? 'Seite' : 'Seiten'} mit je $schreibZeilenProSeite Zeilen',
          knopf: 'Schreibblatt erstellen',
          laeuft: laeuft,
          onPressed: zeilen == 0 ? null : () => erstellen(widget.daten, _speichern),
        ),
      ],
    );
  }
}

class _NeuesLeseblatt extends StatefulWidget {
  const _NeuesLeseblatt({super.key, required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  @override
  State<_NeuesLeseblatt> createState() => _NeuesLeseblattState();
}

class _NeuesLeseblattState extends State<_NeuesLeseblatt> with _Erstellen {
  late final _freiController = TextEditingController(text: widget.profil.freiOhne);

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

  Future<GespeichertesBlatt> _speichern() async {
    final inhalt = erzeugeInhalt(p.buchstaben, ohne: p.ohne, freiOhne: p.freiOhne);
    final (schrift, fett) = await _schriften();
    final pdf = await erstellePdf(inhalt, schrift, fett);
    return widget.daten.speichereBlatt(
      p,
      BlattArt.lesen,
      pdf,
      buchstaben: inhalt.buchstaben,
      ohne: inhalt.ausschluesse,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final regeln = AusschlussRegeln(p.ohne, frei: p.freiOhne);
    final anzahlWoerter = passendeWoerter(p.buchstaben.toSet(), regeln).length;
    final bereit = _hatVokal && _hatMitlaut;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welche Buchstaben kann ${p.name} schon?', style: text.titleMedium),
              const SizedBox(height: 4),
              const Text('Antippen zum Auswählen. Gilt für groß und klein.'),
              const SizedBox(height: 12),
              _BuchstabenWahl(
                auswahl: p.buchstaben,
                aendern: (neu) => _aendern(() => p.buchstaben = neu),
              ),
              const Divider(height: 32),
              Text('Was soll noch nicht vorkommen?', style: text.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Angehakte Kombinationen werden weggelassen, '
                'damit das Blatt zum Leseniveau passt.',
              ),
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
                    onChanged: (an) => _aendern(
                      () => an == true ? p.ohne.add(a.kuerzel) : p.ohne.remove(a.kuerzel),
                    ),
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
            ],
          ),
        ),
        _ErstellenLeiste(
          hinweis: bereit
              ? 'Passende Wörter: $anzahlWoerter'
                    '${anzahlWoerter < 6 ? ' (fehlende Reihen werden mit Silben aufgefüllt)' : ''}'
              : 'Wähle mindestens einen Selbstlaut (A, E, I, O, U) und einen Mitlaut.',
          knopf: 'Leseblatt erstellen',
          laeuft: laeuft,
          onPressed: bereit ? () => erstellen(widget.daten, _speichern) : null,
        ),
      ],
    );
  }
}

class _Gespeichert extends StatelessWidget {
  const _Gespeichert({required this.daten, required this.profil, required this.art});

  final AppDaten daten;
  final Profil profil;
  final BlattArt art;

  String get _name => art == BlattArt.lesen ? 'Leseblatt' : 'Schreibblatt';

  Future<void> _loeschen(BuildContext context, GespeichertesBlatt b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blatt löschen?'),
        content: Text('$_name vom ${datumText(b.erstellt)} wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) await daten.loescheBlatt(b);
  }

  @override
  Widget build(BuildContext context) {
    final liste = daten.blaetterVon(profil, art);
    if (liste.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Für ${profil.name} wurden noch keine ${_name == 'Leseblatt' ? 'Leseblätter' : 'Schreibblätter'} erstellt.',
            textAlign: TextAlign.center,
          ),
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
          subtitle: Text(
            [
              'Buchstaben: ${b.buchstaben.map((x) => x.toUpperCase()).join(' ')}',
              if (b.ohne.isNotEmpty) 'Ohne: ${b.ohne.join(', ')}',
            ].join('\n'),
          ),
          isThreeLine: b.ohne.isNotEmpty,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VorschauSeite(daten: daten, blatt: b),
            ),
          ),
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
