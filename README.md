# Lernapp

Android-App für Eltern, um Lernmaterial für Volksschulkinder zu erstellen.
Gebaut mit Flutter, damit später auch eine iPhone-Version möglich ist.

## Was die App kann

- **Start:** „Deutsch“ und „Mathe“.
- **Deutsch → Wörter und Sätze:** Leseblatt mit Wortreihen und kurzen Sätzen
  (mit Silbenbögen), nur aus bekannten Buchstaben.
- **Deutsch → Lückenwörter:** in jedem Wort fehlt ein Buchstabe; drei
  Buchstaben stehen zur Auswahl.
- **Deutsch → Schreibblätter:** Buchstaben als Vorlage, zweimal strichliert
  zum Nachfahren, dann frei üben – auf Hilfslinien. Auch als leeres Blatt
  nur mit Hilfslinien.
- **Mathe → Zahlen schreiben:** wie die Schreibblätter, mit Ziffern 0–9.
- **Mathe → Rechenblätter:** 24 Aufgaben mit Plus, Minus, Mal und/oder
  Geteilt im Zahlenraum des Kindes (ab 20; bei 20 nur einstellige Zahlen).
- **Deutsch → Leseblätter:** erstellt ein druckbares A4-Leseblatt mit
  Silben und Wörtern, die nur aus den Buchstaben bestehen, die das Kind
  schon kann. 10 Reihen zu je 6 Einträgen, von leicht nach schwer.
  Silbenbögen, Sterne zum Anmalen, Name/Datum-Feld.
- **Ein Profil pro Kind:** Jedes Kind hat seinen eigenen Buchstabenstand und
  eigene Ausschlüsse (z. B. ohne ie, ei, stummes h, doppelte Buchstaben).
  Die Auswahl bleibt gespeichert.
- **Gespeicherte Blätter:** Jedes erstellte Blatt wird mit Datum abgelegt und
  kann später wieder geöffnet, gedruckt oder geteilt werden.
- Funktioniert komplett **offline**, alle Daten bleiben auf dem Gerät.

## App auf dem Handy installieren

1. Am Android-Handy auf GitHub unter **Releases** die neueste
   „Lernapp Testversion“ öffnen und **Lernapp.apk** herunterladen.
2. Die heruntergeladene Datei antippen.
3. Android fragt beim ersten Mal, ob der Browser (bzw. die Dateien-App)
   Apps installieren darf: **Einstellungen → „Dieser Quelle vertrauen“**
   einschalten, zurück, dann **Installieren**.
4. Eine neue Testversion wird genauso installiert und ersetzt die alte;
   Profile und gespeicherte Blätter bleiben erhalten.

## Für Entwickler

```
flutter pub get
flutter test
flutter build apk --release
dart run tool/beispiel.dart a,e,i,o,u,l,s,m,r blatt.pdf ie,ei   # Beispiel-PDFs ohne App
dart run tool/schreibblatt.dart m,a,l blatt.pdf
dart run tool/lesen.dart saetze a,e,i,o,u,l,s,m,r,n,t blatt.pdf   # auch: luecken, linien
dart run tool/mathe.dart rechnen plus,minus 20 blatt.pdf
```

- `lib/generator/` – Generatoren für alle Blätter (Inhalt + PDF), ohne Flutter testbar
- `lib/daten/` – Profile und gespeicherte Blätter (JSON/PDF im App-Ordner)
- `lib/seiten/` – Bildschirme
- `.github/workflows/apk.yml` – baut bei jedem Push die APK und stellt sie
  unter Releases als Testversion bereit

Die APK ist mit einem festen Test-Schlüssel (`android/app/debug.keystore`)
signiert. Für eine Veröffentlichung im Play Store braucht es einen eigenen,
geheimen Schlüssel.

Schrift: „Lernapp Schrift“, abgeleitet von [Andika](https://software.sil.org/andika/)
(SIL Global, SIL Open Font License 1.1, siehe `assets/fonts/OFL.txt`) mit
kleinem „l“ mit Bogen wie in der österreichischen Volksschule. Neu bauen mit
`tool/schrift_bauen.py`.
