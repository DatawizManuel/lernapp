import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../daten/speicher.dart';
import '../generator/inhalt.dart';
import '../generator/luecken.dart';
import '../generator/pdf.dart';
import '../generator/rechnen.dart';
import '../generator/saetze.dart';
import '../generator/schreiben.dart';
import 'profile.dart';
import 'vorschau.dart';

/// Seite für eine Blatt-Art (Lese-, Schreib-, Zahlen- oder Rechenblätter) mit den
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
              title: Text(art.titel),
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
                      switch (art) {
                        BlattArt.lesen || BlattArt.saetze || BlattArt.luecken => _NeuesLeseblatt(
                          key: ValueKey((profil.id, art)),
                          daten: daten,
                          profil: profil,
                          art: art,
                        ),
                        BlattArt.schreiben => _NeuesSchreibblatt(
                          key: ValueKey(profil.id),
                          daten: daten,
                          profil: profil,
                        ),
                        BlattArt.zahlen => _NeuesZahlenblatt(
                          key: ValueKey(profil.id),
                          daten: daten,
                          profil: profil,
                        ),
                        BlattArt.rechnen => _NeuesRechenblatt(
                          key: ValueKey(profil.id),
                          daten: daten,
                          profil: profil,
                        ),
                      },
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

const _buchstabenHinweis =
    'Antippen zum Auswählen. Die Auswahl gilt für alle Übungen (Lesen und Schreiben).';

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

/// Zahlen-Schreibblatt: Ziffern auswählen.
class _NeuesZahlenblatt extends StatefulWidget {
  const _NeuesZahlenblatt({super.key, required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  @override
  State<_NeuesZahlenblatt> createState() => _NeuesZahlenblattState();
}

class _NeuesZahlenblattState extends State<_NeuesZahlenblatt> with _Erstellen {
  Profil get p => widget.profil;

  void _aendern(VoidCallback aenderung) {
    setState(aenderung);
    widget.daten.profilGeaendert();
  }

  Future<GespeichertesBlatt> _speichern() async {
    final (schrift, fett) = await _schriften();
    final pdf = await erstelleZahlenSchreibPdf(p.ziffern, schrift, fett);
    final ziffern = alleZiffern.where(p.ziffern.contains).toList();
    return widget.daten.speichereBlatt(
      p,
      BlattArt.zahlen,
      pdf,
      buchstaben: ziffern,
      info: 'Zahlen: ${ziffern.join(' ')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final seiten = (zahlenZeilen(p.ziffern).length / schreibZeilenProSeite).ceil();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welche Zahlen soll ${p.name} schreiben üben?', style: text.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final z in alleZiffern)
                    FilterChip(
                      label: Text(z, style: const TextStyle(fontSize: 16)),
                      selected: p.ziffern.contains(z),
                      onSelected: (an) => _aendern(
                        () => p.ziffern = alleZiffern
                            .where((x) => x == z ? an : p.ziffern.contains(x))
                            .toList(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Jede Zeile beginnt mit der Zahl als Vorlage, danach zweimal '
                'strichliert zum Nachfahren. Der Rest der Zeile ist frei zum Üben.',
              ),
            ],
          ),
        ),
        _ErstellenLeiste(
          hinweis: seiten == 0
              ? 'Wähle mindestens eine Zahl.'
              : '$seiten ${seiten == 1 ? 'Seite' : 'Seiten'} mit je $schreibZeilenProSeite Zeilen',
          knopf: 'Zahlenblatt erstellen',
          laeuft: laeuft,
          onPressed: seiten == 0 ? null : () => erstellen(widget.daten, _speichern),
        ),
      ],
    );
  }
}

/// Rechenblatt: Rechenarten und Zahlenraum (gelten für alle Mathe-Übungen).
class _NeuesRechenblatt extends StatefulWidget {
  const _NeuesRechenblatt({super.key, required this.daten, required this.profil});

  final AppDaten daten;
  final Profil profil;

  @override
  State<_NeuesRechenblatt> createState() => _NeuesRechenblattState();
}

class _NeuesRechenblattState extends State<_NeuesRechenblatt> with _Erstellen {
  late final _raumController = TextEditingController(text: '${widget.profil.zahlenraum}');
  String? _raumFehler;

  Profil get p => widget.profil;

  @override
  void dispose() {
    _raumController.dispose();
    super.dispose();
  }

  void _aendern(VoidCallback aenderung) {
    setState(aenderung);
    widget.daten.profilGeaendert();
  }

  void _raumGeaendert(String eingabe) {
    final wert = int.tryParse(eingabe.trim());
    if (wert == null || wert < zahlenraumMin || wert > zahlenraumMax) {
      setState(() => _raumFehler = 'Bitte eine Zahl von $zahlenraumMin bis $zahlenraumMax');
      return;
    }
    _raumFehler = null;
    _aendern(() => p.zahlenraum = wert);
  }

  Future<GespeichertesBlatt> _speichern() async {
    final (schrift, fett) = await _schriften();
    final arten = Rechenart.values.where(p.rechenarten.contains).toList();
    final pdf = await erstelleRechenPdf(arten, p.zahlenraum, schrift, fett);
    return widget.daten.speichereBlatt(
      p,
      BlattArt.rechnen,
      pdf,
      buchstaben: [for (final a in arten) a.zeichen],
      info: 'Bis ${p.zahlenraum}: ${arten.map((a) => a.bezeichnung).join(', ')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bereit = p.rechenarten.isNotEmpty && _raumFehler == null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Bis wohin rechnet ${p.name}?', style: text.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _raumController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Zahlenraum',
                  prefixText: 'bis ',
                  helperText: 'Im Zahlenraum 20 kommen nur einstellige Zahlen vor.',
                  errorText: _raumFehler,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _raumGeaendert,
              ),
              const Divider(height: 32),
              Text('Welche Rechenarten?', style: text.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final art in Rechenart.values)
                    FilterChip(
                      label: Text(
                        '${art.zeichen}  ${art.bezeichnung}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      selected: p.rechenarten.contains(art),
                      onSelected: (an) => _aendern(
                        () => p.rechenarten = Rechenart.values
                            .where((x) => x == art ? an : p.rechenarten.contains(x))
                            .toList(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Die Ergebnisse bleiben im Zahlenraum. Minus wird nie negativ, Geteilt geht '
                'immer ohne Rest auf. Mal und Geteilt bleiben bis 100 beim Einmaleins. '
                'Zahlenraum und Rechenarten gelten für alle Mathe-Übungen.',
              ),
            ],
          ),
        ),
        _ErstellenLeiste(
          hinweis: p.rechenarten.isEmpty
              ? 'Wähle mindestens eine Rechenart.'
              : '$aufgabenProSeite Aufgaben bis ${p.zahlenraum}',
          knopf: 'Rechenblatt erstellen',
          laeuft: laeuft,
          onPressed: bereit ? () => erstellen(widget.daten, _speichern) : null,
        ),
      ],
    );
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
    final pdf = await erstelleSchreibPdf(p.buchstaben, p.schreibForm, schrift, fett);
    return widget.daten.speichereBlatt(
      p,
      BlattArt.schreiben,
      pdf,
      buchstaben: sortiereBuchstaben(p.buchstaben),
    );
  }

  Future<GespeichertesBlatt> _linienSpeichern() async {
    final (schrift, fett) = await _schriften();
    final pdf = await erstelleLinienPdf(schrift, fett);
    return widget.daten.speichereBlatt(
      p,
      BlattArt.schreiben,
      pdf,
      buchstaben: const [],
      info: 'Nur Hilfslinien',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final zeilen = schreibZeilen(p.buchstaben, p.schreibForm).length;
    final seiten = (zeilen / schreibZeilenProSeite).ceil();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welche Buchstaben kann ${p.name} schon?', style: text.titleMedium),
              const SizedBox(height: 4),
              const Text(_buchstabenHinweis),
              const SizedBox(height: 12),
              _BuchstabenWahl(
                auswahl: p.buchstaben,
                aendern: (neu) => _aendern(() => p.buchstaben = neu),
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
              const Divider(height: 32),
              Text('Leeres Blatt', style: text.titleMedium),
              const SizedBox(height: 4),
              const Text('Nur Hilfslinien, ohne Vorlage – zum freien Schreiben.'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.horizontal_rule),
                  label: const Text('Blatt mit Hilfslinien erstellen'),
                  onPressed: laeuft ? null : () => erstellen(widget.daten, _linienSpeichern),
                ),
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

/// Lese-Übungen mit Buchstaben und Ausschlüssen: Leseblatt (Silben und
/// Wörter), Wörter und Sätze, Lückenwörter.
class _NeuesLeseblatt extends StatefulWidget {
  const _NeuesLeseblatt({super.key, required this.daten, required this.profil, required this.art});

  final AppDaten daten;
  final Profil profil;
  final BlattArt art;

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
    final (schrift, fett) = await _schriften();
    final regeln = AusschlussRegeln(p.ohne, frei: p.freiOhne);
    final pdf = switch (widget.art) {
      BlattArt.saetze => await erstelleSatzPdf(
        erzeugeSatzblatt(p.buchstaben, ohne: p.ohne, freiOhne: p.freiOhne),
        schrift,
        fett,
      ),
      BlattArt.luecken => await erstelleLueckenPdf(
        p.buchstaben,
        erzeugeLueckenwoerter(p.buchstaben, ohne: p.ohne, freiOhne: p.freiOhne),
        regeln.beschreibungen,
        schrift,
        fett,
      ),
      _ => await erstellePdf(
        erzeugeInhalt(p.buchstaben, ohne: p.ohne, freiOhne: p.freiOhne),
        schrift,
        fett,
      ),
    };
    return widget.daten.speichereBlatt(
      p,
      widget.art,
      pdf,
      buchstaben: sortiereBuchstaben(p.buchstaben),
      ohne: regeln.beschreibungen,
    );
  }

  /// Hinweis unter der Auswahl und ob das Blatt erstellt werden kann.
  (String, bool) _stand() {
    if (!_hatVokal || !_hatMitlaut) {
      return ('Wähle mindestens einen Selbstlaut (A, E, I, O, U) und einen Mitlaut.', false);
    }
    final erlaubt = p.buchstaben.toSet();
    final regeln = AusschlussRegeln(p.ohne, frei: p.freiOhne);
    final woerter = passendeWoerter(erlaubt, regeln);
    switch (widget.art) {
      case BlattArt.saetze:
        final saetze = passendeSaetze(erlaubt, regeln).length;
        return (
          'Passende Wörter: ${woerter.length}, passende Sätze: $saetze'
              '${saetze < satzblattSaetzeMax ? ' (mit mehr Buchstaben, z. B. N und T, gibt es viel mehr Sätze)' : ''}',
          woerter.isNotEmpty || saetze > 0,
        );
      case BlattArt.luecken:
        final anzahl = woerter.where((w) => w.replaceAll('-', '').length >= 3).length;
        return (
          anzahl == 0
              ? 'Mit diesen Buchstaben gibt es noch keine passenden Wörter.'
              : 'Passende Wörter: $anzahl',
          anzahl > 0,
        );
      default:
        return (
          'Passende Wörter: ${woerter.length}'
              '${woerter.length < 6 ? ' (fehlende Reihen werden mit Silben aufgefüllt)' : ''}',
          true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (hinweis, bereit) = _stand();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Welche Buchstaben kann ${p.name} schon?', style: text.titleMedium),
              const SizedBox(height: 4),
              const Text(_buchstabenHinweis),
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
          hinweis: hinweis,
          knopf: '${widget.art.einzahl} erstellen',
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

  Future<void> _loeschen(BuildContext context, GespeichertesBlatt b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blatt löschen?'),
        content: Text('${b.art.einzahl} vom ${datumText(b.erstellt)} wird gelöscht.'),
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
            'Für ${profil.name} wurden noch keine ${art.mehrzahl} erstellt.',
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
              b.info ?? 'Buchstaben: ${b.buchstaben.map((x) => x.toUpperCase()).join(' ')}',
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
