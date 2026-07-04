# Building OpeningsMastermind

These are the steps to build the app from source. If you just want to use the
app, [download it from the App Store](https://apps.apple.com/app/openings-mastermind/id6448386251).

## Requirements

- **macOS** with **Xcode 16** or later
- Targets **iOS 18.6+** (iPhone and iPad)

Swift package dependencies (ChessKit, ChessKitEngine, TelemetryDeck, Textual)
resolve automatically through Xcode on first open — no manual setup.

## 1. Clone the repository

```bash
git clone https://github.com/christian-heise/OpeningsMastermind.git
cd OpeningsMastermind
```

## 2. Download the Stockfish neural networks

The app bundles **Stockfish** for engine analysis. ChessKitEngine ships Stockfish
without an embedded network, so two NNUE files must be present in
`OpeningsMastermind/Data/` before you build. They are **not** committed to the
repository (71 MB + 3.4 MB of immutable binary); a script fetches them from
Stockfish's official host and verifies each file's checksum:

```bash
./Scripts/download_nnue.sh
```

Re-running it is safe — files already present with a valid hash are skipped.
Without these files the app compiles but the engine will fail to load its network
at runtime.

## 3. Configure secrets (optional)

Analytics (TelemetryDeck) reads its app ID from `OpeningsMastermind/Config.xcconfig`,
which is gitignored. For a local build you can copy the example placeholder:

```bash
cp OpeningsMastermind/Config.xcconfig.example OpeningsMastermind/Config.xcconfig
```

Leaving the ID blank simply disables analytics — the app builds and runs fine
without it.

## 4. Build and run

Open the project in Xcode, select an **iOS Simulator** destination (e.g.
`iPhone 17`), and build/run:

```bash
open OpeningsMastermind.xcodeproj
```

Or from the command line:

```bash
xcodebuild -scheme OpeningsMastermind -project OpeningsMastermind.xcodeproj build \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

## Running the tests

```bash
xcodebuild test -scheme OpeningsMastermind -project OpeningsMastermind.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

Some tests read fixture files from disk and therefore require a **Simulator**
destination (not a physical device).
