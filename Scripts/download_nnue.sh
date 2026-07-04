#!/usr/bin/env bash
# download_nnue.sh
#
# Downloads the two Stockfish NNUE network files the app bundles as resources
# into OpeningsMastermind/Data/. These files are gitignored (71 MB + 3.4 MB of
# immutable binary), so this script must be run once before the first build.
#
# ChessKitEngine 0.7.0 compiles Stockfish with NNUE_EMBEDDING_OFF, so the
# networks must be present in the app's Copy Bundle Resources phase at build
# time (see CLAUDE.md → Engine). Each filename's hash is the first 12 hex chars
# of the file's SHA-256, which this script verifies after download.
#
# Usage: ./Scripts/download_nnue.sh
#        Run from the repo root. Skips files already present and valid.

set -euo pipefail

DEST="$(dirname "$0")/../OpeningsMastermind/Data"
mkdir -p "$DEST"

# Source: Stockfish's official network host. The tests.stockfishchess.org
# endpoint 302-redirects to data.stockfishchess.org (curl -L follows).
BASE_URL="https://tests.stockfishchess.org/api/nn"

# The networks the app currently expects. Update these when bumping the
# Stockfish/ChessKitEngine version (the hash is baked into the filename).
FILES=(
    "nn-1111cefa1111.nnue"  # EvalFile     (~71 MB)
    "nn-37f18f62d772.nnue"  # EvalFileSmall (~3.4 MB)
)

# Portable SHA-256 helper (shasum on macOS, sha256sum on Linux).
sha256_12() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | cut -c1-12
    else
        sha256sum "$1" | cut -c1-12
    fi
}

# Expected hash is the 12 hex chars between "nn-" and ".nnue".
expected_hash() {
    local f="$1"
    f="${f#nn-}"
    echo "${f%.nnue}"
}

ok=0
skip=0
fail=0

for f in "${FILES[@]}"; do
    dest_file="$DEST/$f"
    want="$(expected_hash "$f")"

    if [ -f "$dest_file" ] && [ "$(sha256_12 "$dest_file")" = "$want" ]; then
        echo "Skipping $f (already present, hash OK)"
        (( skip++ )) || true
        continue
    fi

    printf "Downloading %-22s ... " "$f"
    if curl -fsSL --max-time 300 "$BASE_URL/$f" -o "$dest_file"; then
        got="$(sha256_12 "$dest_file")"
        if [ "$got" = "$want" ]; then
            size=$(wc -c < "$dest_file")
            printf "OK (%d MB, hash verified)\n" $(( size / 1024 / 1024 ))
            (( ok++ )) || true
        else
            rm -f "$dest_file"
            echo "FAILED (hash mismatch: expected $want, got $got)"
            (( fail++ )) || true
        fi
    else
        rm -f "$dest_file"
        echo "FAILED (curl error)"
        (( fail++ )) || true
    fi
done

echo ""
echo "Done: $ok downloaded, $skip skipped, $fail failed."
echo "Files are in: $DEST"

if [ "$fail" -gt 0 ]; then
    exit 1
fi
