#!/usr/bin/env bash
# Render the Phase 0 concept model: PNG views into docs/images/concept/, STLs into cad/concept/stl/.
# Needs OpenSCAD (tested with 2021.01) and, on a headless machine, xvfb-run. Graphviz `dot` for the wiring diagram.
set -euo pipefail
cd "$(dirname "$0")"
SCAD=concept.scad
IMG=../../docs/images/concept
STL=stl
mkdir -p "$IMG" "$STL"

run() { if [ -n "${DISPLAY:-}" ]; then openscad "$@"; else xvfb-run -a openscad "$@"; fi; }

# name | view | camera (gimbal: translate x,y,z, rotate x,y,z, distance)
png() {
  run -o "$IMG/$1.png" -D "view=\"$2\"" --camera="$3" --imgsize=1400,1100 \
      --colorscheme=Tomorrow --projection=p "$SCAD" 2>&1 | grep -E "WARNING|ERROR" || true
}
png concept_assembly_front  assembly    "23,14,48,68,0,30,300"
png concept_assembly_back   back        "23,14,48,68,0,-150,300"
png concept_cutaway         cutaway     "23,14,50,70,0,25,260"
png concept_electronics     electronics "23,10,50,78,0,10,340"
png concept_section         section     "23,-20,48,90,0,-90,300"
png concept_exploded        exploded    "23,-10,44,66,0,-58,360"
png concept_parts           parts       "85,14,40,55,0,10,400"

for part in back_plate body_shell pod_shell electronics; do
  run -o "$STL/concept_$part.stl" -D "view=\"part_$part\"" "$SCAD" 2>&1 | grep -E "WARNING|ERROR" || true
done

dot -Tsvg wiring_concept.dot -o "$IMG/wiring_concept.svg"
dot -Tpng -Gdpi=110 wiring_concept.dot -o "$IMG/wiring_concept.png"
echo "done"
