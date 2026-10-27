# Lernapp

Android-App für Eltern, um Lernmaterial für Volksschulkinder zu erstellen.
Gebaut mit Flutter, damit später auch eine iPhone-Version möglich ist.

## Was die App kann

- **Start:** „Deutsch“ und „Mathe“ (Mathe kommt später).
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
dart run tool/beispiel.dart a,e,i,o,u,l,s,m,r blatt.pdf ie,ei   # Beispiel-PDF ohne App
```

- `lib/generator/` – Leseblatt-Generator (Inhalt + PDF), ohne Flutter testbar
- `lib/daten/` – Profile und gespeicherte Blätter (JSON/PDF im App-Ordner)
- `lib/seiten/` – Bildschirme
- `.github/workflows/apk.yml` – baut bei jedem Push die APK und stellt sie
  unter Releases als Testversion bereit

Die APK ist mit einem festen Test-Schlüssel (`android/app/debug.keystore`)
signiert. Für eine Veröffentlichung im Play Store braucht es einen eigenen,
geheimen Schlüssel.

Schrift: [Andika](https://software.sil.org/andika/) von SIL International,
SIL Open Font License 1.1.
