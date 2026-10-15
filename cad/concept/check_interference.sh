#!/usr/bin/env bash
# Concept-level interference check: every board and the wiring against every case part, and the case
# parts against each other. Each pair is intersected with CGAL; an empty result means no overlap.
# This checks the concept's own numbers only. Real board sizes still have to be measured (Phase 3).
set -uo pipefail
cd "$(dirname "$0")"
here=$(pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

run() { if [ -n "${DISPLAY:-}" ]; then openscad "$@"; else xvfb-run -a openscad "$@"; fi; }

pair() {  # $1, $2: module calls
  cat > "$tmp/pair.scad" <<EOF
use <$(pwd)/concept.scad>
intersection() { $1; $2; }
EOF
  out=$(run -o "$tmp/pair.stl" "$tmp/pair.scad" 2>&1)
  if grep -q -E "top level object is empty|No top level geometry" <<<"$out"; then
    printf 'ok       %-14s x %s\n' "$1" "$2"; return
  fi
  # Non-empty: measure the overlap volume. Faces that only touch give ~0 mm^3.
  vol=$(python3 -I "$here/stl_volume.py" "$tmp/pair.stl")
  if python3 -c "import sys; sys.exit(0 if abs(float('$vol')) < 0.01 else 1)"; then
    printf 'touch    %-14s x %-14s (%s mm^3)\n' "$1" "$2" "$vol"
  else
    printf 'OVERLAP  %-14s x %-14s (%s mm^3)\n' "$1" "$2" "$vol"; fail=1
  fi
}

fail=0
for part in "back_plate()" "body_shell()" "pod_shell()"; do
  for item in "xiao()" "ld2412()" "opt3001()" "sht45()" "antenna()" "wiring()"; do
    pair "$part" "$item"
  done
done
pair "back_plate()" "body_shell()"
pair "back_plate()" "pod_shell()"
pair "body_shell()" "pod_shell()"
exit $fail
