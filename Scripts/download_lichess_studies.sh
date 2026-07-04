#!/usr/bin/env bash
# download_lichess_studies.sh
#
# Downloads a curated set of Lichess studies into
# OpeningsMastermindTests/LichessStudies/ for use by LichessStudyStressTests.
#
# Usage: ./Scripts/download_lichess_studies.sh
#        Run from the repo root. Refreshes (overwrites) existing files.

set -euo pipefail

DEST="$(dirname "$0")/../OpeningsMastermindTests/LichessStudies"
mkdir -p "$DEST"

# ---------------------------------------------------------------------------
# Curated study list – add more IDs here to expand the corpus.
#
# Format: "id  # name / description"
# ---------------------------------------------------------------------------
declare -A STUDIES=(
    # App's own opening repertoire studies
    [udExyu0p]="Danish Gambit Refutation"
    [Rvu7G9VX]="Caro-Kann Goldman Variation"
    [inBWS4oN]="Crushing the Englund Gambit"
    [d05kyFwr]="Scotch Gambit"
    [ccnOaWVC]="Smith-Morra Gambit In-Depth"

    # Lichess official annotated tournament studies (large, deeply annotated)
    [Y1yXP80U]="FIDE Candidates 2026 Annotations (~375 KB)"
    [y4CM41x8]="Tata Steel Chess 2026 Annotations"
    [9c2VHkcn]="FIDE World Cup 2025 Annotations"
    [9LjyYZ9N]="FIDE World Rapid & Blitz 2025 Puzzle Pack (gamebook, exempt from rich-tree checks)"

    # Candidates 2026 round studies
    [7rt7dV7n]="Candidates 2026 – Round 1"
    [2VMSxOmp]="Candidates 2026 – Round 2"
    [vMRPidev]="Candidates 2026 – Round 3"
    [3FDmXBwK]="Candidates 2026 – Round 4"
    [zkwPbfMN]="Candidates 2026 – Round 5"

    # World Cup 2025 round studies
    [uvJTjfi6]="World Cup 2025 – Round 7"
    [oRYGBEaf]="World Cup 2025 – Round 6"
    [QLUxlqXC]="World Cup 2025 – QF/other"
)

ok=0
skip=0

for id in "${!STUDIES[@]}"; do
    name="${STUDIES[$id]}"
    dest_file="$DEST/${id}.pgn"

    printf "Downloading %-12s  %s ... " "$id" "$name"
    if curl -fsSL --max-time 60 "https://lichess.org/api/study/${id}.pgn" -o "$dest_file" 2>/dev/null; then
        size=$(wc -c < "$dest_file")
        if grep -q "DOCTYPE" "$dest_file" 2>/dev/null || [ "$size" -lt 1000 ]; then
            rm -f "$dest_file"
            echo "SKIP (not a valid PGN)"
            (( skip++ )) || true
        else
            printf "OK (%d KB)\n" $(( size / 1024 ))
            (( ok++ )) || true
        fi
    else
        echo "FAILED (curl error)"
        (( skip++ )) || true
    fi
done

echo ""
echo "Done: $ok downloaded, $skip skipped/failed."
echo "Files are in: $DEST"
