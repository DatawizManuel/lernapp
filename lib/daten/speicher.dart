/// Lokale Ablage auf dem Gerät: Profile (ein Profil pro Kind) und
/// gespeicherte Leseblätter. Alles liegt als JSON bzw. PDF im
/// App-Dokumentenordner, es wird nichts ins Internet übertragen.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../generator/schreiben.dart' show SchreibForm;

class Profil {
  Profil({
    required this.id,
    required this.name,
    List<String>? buchstaben,
    List<String>? ohne,
    this.freiOhne = '',
    List<String>? schreibBuchstaben,
    this.schreibForm = SchreibForm.beide,
  }) : buchstaben = buchstaben ?? [],
       ohne = ohne ?? [],
       schreibBuchstaben = schreibBuchstaben ?? [];

  factory Profil.fromJson(Map<String, dynamic> j) => Profil(
    id: j['id'] as String,
    name: j['name'] as String,
    buchstaben: List<String>.from(j['buchstaben'] as List? ?? []),
    ohne: List<String>.from(j['ohne'] as List? ?? []),
    freiOhne: j['freiOhne'] as String? ?? '',
    schreibBuchstaben: List<String>.from(j['schreibBuchstaben'] as List? ?? []),
    schreibForm: SchreibForm.values.asNameMap()[j['schreibForm']] ?? SchreibForm.beide,
  );

  final String id;
  String name;

  /// Gelernte Buchstaben, klein geschrieben (gilt für groß und klein).
  List<String> buchstaben;

  /// Kürzel der ausgeschlossenen Kombinationen (siehe [ausschluesse]).
  List<String> ohne;

  /// Weitere auszuschließende Buchstabenfolgen, z. B. "ll, rr".
  String freiOhne;

  /// Buchstaben für das Schreibblatt (klein geschrieben).
  List<String> schreibBuchstaben;
  SchreibForm schreibForm;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'buchstaben': buchstaben,
    'ohne': ohne,
    'freiOhne': freiOhne,
    'schreibBuchstaben': schreibBuchstaben,
    'schreibForm': schreibForm.name,
  };
}

/// Art eines gespeicherten Blatts.
enum BlattArt { lesen, schreiben }

class GespeichertesBlatt {
  GespeichertesBlatt({
    this.art = BlattArt.lesen,
    required this.datei,
    required this.profilId,
    required this.erstellt,
    required this.buchstaben,
    required this.ohne,
  });

  factory GespeichertesBlatt.fromJson(Map<String, dynamic> j) => GespeichertesBlatt(
    art: BlattArt.values.asNameMap()[j['art']] ?? BlattArt.lesen,
    datei: j['datei'] as String,
    profilId: j['profilId'] as String,
    erstellt: DateTime.parse(j['erstellt'] as String),
    buchstaben: List<String>.from(j['buchstaben'] as List),
    ohne: List<String>.from(j['ohne'] as List? ?? []),
  );

  final BlattArt art;

  /// Dateiname im Blätter-Ordner.
  final String datei;
  final String profilId;
  final DateTime erstellt;
  final List<String> buchstaben;
  final List<String> ohne;

  Map<String, dynamic> toJson() => {
    'art': art.name,
    'datei': datei,
    'profilId': profilId,
    'erstellt': erstellt.toIso8601String(),
    'buchstaben': buchstaben,
    'ohne': ohne,
  };
}

String _zwei(int n) => n.toString().padLeft(2, '0');

String datumText(DateTime d) =>
    '${_zwei(d.day)}.${_zwei(d.month)}.${d.year}, ${_zwei(d.hour)}:${_zwei(d.minute)} Uhr';

/// Hält alle Daten der App und speichert jede Änderung sofort.
class AppDaten extends ChangeNotifier {
  AppDaten(this._ordner);

  final Directory _ordner;
  final profile = <Profil>[];
  final blaetter = <GespeichertesBlatt>[];
  String? _aktivId;

  File get _profilDatei => File('${_ordner.path}/profile.json');
  Directory get blattOrdner => Directory('${_ordner.path}/leseblaetter');
  File get _blattIndex => File('${blattOrdner.path}/index.json');

  static Future<AppDaten> laden(Directory ordner) async {
    final d = AppDaten(ordner);
    await d.blattOrdner.create(recursive: true);
    if (await d._profilDatei.exists()) {
      final j = jsonDecode(await d._profilDatei.readAsString()) as Map<String, dynamic>;
      d.profile.addAll(
        (j['profile'] as List).map((p) => Profil.fromJson(p as Map<String, dynamic>)),
      );
      d._aktivId = j['aktiv'] as String?;
    }
    if (await d._blattIndex.exists()) {
      final liste = jsonDecode(await d._blattIndex.readAsString()) as List;
      d.blaetter.addAll(liste.map((b) => GespeichertesBlatt.fromJson(b as Map<String, dynamic>)));
    }
    return d;
  }

  Profil? get aktivesProfil {
    for (final p in profile) {
      if (p.id == _aktivId) return p;
    }
    return profile.isEmpty ? null : profile.first;
  }

  Future<void> waehleProfil(Profil p) async {
    _aktivId = p.id;
    await _profileSpeichern();
  }

  Future<Profil> neuesProfil(String name) async {
    final p = Profil(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name.trim());
    profile.add(p);
    _aktivId = p.id;
    await _profileSpeichern();
    return p;
  }

  /// Nach jeder Änderung an einem Profil aufrufen.
  Future<void> profilGeaendert() => _profileSpeichern();

  Future<void> loescheProfil(Profil p) async {
    for (final b in blaetterVon(p).toList()) {
      await _dateiLoeschen(b);
      blaetter.remove(b);
    }
    profile.remove(p);
    if (_aktivId == p.id) _aktivId = profile.isEmpty ? null : profile.first.id;
    await _indexSpeichern();
    await _profileSpeichern();
  }

  /// Blätter eines Profils (optional nur einer Art), die neuesten zuerst.
  List<GespeichertesBlatt> blaetterVon(Profil p, [BlattArt? art]) =>
      blaetter.where((b) => b.profilId == p.id && (art == null || b.art == art)).toList()
        ..sort((a, b) => b.erstellt.compareTo(a.erstellt));

  File dateiVon(GespeichertesBlatt b) => File('${blattOrdner.path}/${b.datei}');

  Future<GespeichertesBlatt> speichereBlatt(
    Profil p,
    BlattArt art,
    Uint8List pdf, {
    required List<String> buchstaben,
    List<String> ohne = const [],
  }) async {
    final jetzt = DateTime.now();
    final praefix = art == BlattArt.lesen ? 'Leseblatt' : 'Schreibblatt';
    final name =
        '${praefix}_${_dateiname(p.name)}_${jetzt.year}-${_zwei(jetzt.month)}-'
        '${_zwei(jetzt.day)}_${_zwei(jetzt.hour)}-${_zwei(jetzt.minute)}-${_zwei(jetzt.second)}.pdf';
    await File('${blattOrdner.path}/$name').writeAsBytes(pdf, flush: true);
    final b = GespeichertesBlatt(
      art: art,
      datei: name,
      profilId: p.id,
      erstellt: jetzt,
      buchstaben: buchstaben,
      ohne: ohne,
    );
    blaetter.add(b);
    await _indexSpeichern();
    return b;
  }

  Future<void> loescheBlatt(GespeichertesBlatt b) async {
    await _dateiLoeschen(b);
    blaetter.remove(b);
    await _indexSpeichern();
  }

  Future<void> _dateiLoeschen(GespeichertesBlatt b) async {
    final f = dateiVon(b);
    if (await f.exists()) await f.delete();
  }

  static String _dateiname(String s) {
    final t = s
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('Ä', 'Ae')
        .replaceAll('Ö', 'Oe')
        .replaceAll('Ü', 'Ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    return t.isEmpty ? 'Kind' : t;
  }

  Future<void> _profileSpeichern() async {
    await _schreibe(_profilDatei, {
      'aktiv': _aktivId,
      'profile': profile.map((p) => p.toJson()).toList(),
    });
    notifyListeners();
  }

  Future<void> _indexSpeichern() async {
    await _schreibe(_blattIndex, blaetter.map((b) => b.toJson()).toList());
    notifyListeners();
  }

  /// Erst in eine Hilfsdatei schreiben, dann umbenennen: so bleibt die
  /// Datei auch bei einem Absturz mitten im Schreiben lesbar.
  static Future<void> _schreibe(File ziel, Object daten) async {
    final tmp = File('${ziel.path}.tmp');
    await tmp.writeAsString(jsonEncode(daten), flush: true);
    await tmp.rename(ziel.path);
  }
}
