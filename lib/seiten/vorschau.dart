import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../daten/speicher.dart';

/// Zeigt ein gespeichertes Leseblatt an; Drucken und Teilen gehen über die
/// Knöpfe unten.
class VorschauSeite extends StatelessWidget {
  const VorschauSeite({super.key, required this.daten, required this.blatt, this.neu = false});

  final AppDaten daten;
  final GespeichertesBlatt blatt;

  /// Gerade erstellt (dann kurzer Hinweis, dass es gespeichert wurde).
  final bool neu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(neu ? 'Neues Leseblatt' : datumText(blatt.erstellt))),
      body: Column(children: [
        if (neu)
          MaterialBanner(
            content: const Text('Gespeichert. Du findest das Blatt später unter „Gespeichert“.'),
            leading: const Icon(Icons.check_circle_outline),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zurück'),
              ),
            ],
          ),
        Expanded(
          child: PdfPreview(
            build: (_) => daten.dateiVon(blatt).readAsBytes(),
            pdfFileName: blatt.datei,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          ),
        ),
      ]),
    );
  }
}
