<p align="right"><a href="README.md">🇺🇸 English</a></p>

<p align="center">
  <img src=".github/screenshots/AppIcon.png" width="120" alt="OpeningsMastermind App-Icon" />
</p>

<h1 align="center">OpeningsMastermind</h1>

<p align="center"><strong>Lerne Schacheröffnungen so, wie du sie wirklich spielst.</strong></p>

<p align="center">
  <a href="https://apps.apple.com/de/app/openings-mastermind/id6448386251">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/de-de?size=250x83" height="56" alt="Laden im App Store" />
  </a>
</p>

OpeningsMastermind ist eine iOS-App zum Studieren von Schacheröffnungen. Importiere
jede Eröffnung als PGN-Datei oder [Lichess-Studie](https://lichess.org/study),
erkunde sie auf einem voll interaktiven Brett, erhalte eine sofortige
Engine-Bewertung, sieh dir an, wie die Profis jeden Zug spielen, und präge dir die
Varianten mit Wiederholungstraining nachhaltig ein.

<p align="center">
  <img src=".github/screenshots/Explorer.png" width="24%" alt="Explorer" />
  <img src=".github/screenshots/Library.png" width="24%" alt="Bibliothek" />
  <img src=".github/screenshots/Practice.png" width="24%" alt="Training" />
  <img src=".github/screenshots/CustomizeBoard.png" width="24%" alt="Brett anpassen" />
</p>

## Funktionen

- **Erkunden** — Gehe deine Eröffnungen Zug für Zug auf einem interaktiven Brett
  durch, mit einer Live-Bewertungsleiste von Stockfish und Hinweisen zum besten Zug.
- **Eröffnungs-Explorer** — Sieh dir echte Zughäufigkeiten und Gewinnraten direkt
  aus dem Lichess-Eröffnungs-Explorer an.
- **Training** — Übe dein Repertoire mit integriertem Wiederholungstraining, das
  die Wiederholungen danach plant, wie gut du jede Variante beherrschst.
- **Alles importieren** — Füge rohes PGN ein, lade eine Lichess-Studie per URL oder
  starte mit den mitgelieferten Beispielstudien.
- **Ganz nach deinem Geschmack** — Passe Brettfarben und Figurenstil an, wähle die
  Geschwindigkeit der Zuganimation und wechsle zwischen Deutsch und Englisch.
- **Datenschutz von Grund auf** — Analyse und Absturzberichte sind vollständig
  optional und lassen sich in den Einstellungen ausschalten.

## Neu in v0.9

- Neues Erscheinungsbild rund um Apples neues **Liquid-Glass**-Design
- **Deutsche Sprachunterstützung** — umschaltbar unter Einstellungen → Allgemein
- Zuverlässigerer PGN-Import: ein neu geschriebener Parser unterstützt deutlich
  mehr Lichess-Studien und PGN-Dateien korrekt
- Abstürze bei sehr tiefen oder sich wiederholenden Eröffnungslinien behoben
- Seltenen Absturz im Zusammenhang mit der Schach-Engine behoben
- Neue Datenschutzeinstellungen: Analyse und Absturzberichte in den Einstellungen
  ein- oder ausschaltbar
- Verschiedene Stabilitäts- und Leistungsverbesserungen

## Voraussetzungen

- **iOS 18.6** oder neuer
- **iPhone und iPad** (universelle App)

## Aus dem Quellcode bauen

Du möchtest die App selbst bauen? Siehe [`BUILDING.md`](BUILDING.md) für die
komplette Einrichtung, einschließlich des einmaligen Schritts
[`Scripts/download_nnue.sh`](Scripts/download_nnue.sh), der Stockfishs neuronale
Netzdateien herunterlädt (sie liegen nicht im Repository).

## Warum dieses Repository öffentlich ist

OpeningsMastermind bündelt **[Stockfish](https://stockfishchess.org/)** (über
[ChessKitEngine](https://github.com/chesskit-app/chesskit-engine)), das unter der
**GNU General Public License v3** lizenziert ist. Die Verbreitung der App
verpflichtet uns daher, den vollständigen zugehörigen Quellcode anzubieten — und
dieses Repository ist dieser Quellcode. Folglich wird die gesamte App unter der
GPLv3 veröffentlicht.

## Lizenz

Copyright © Christian Heise.

Lizenziert unter der GNU General Public License v3.0 oder neuer. Den vollständigen
Text findest du in [`LICENSE`](LICENSE).
