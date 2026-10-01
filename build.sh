#!/usr/bin/env bash
# Export every printable part and the README renders from devin_local_london.scad.
# Needs OpenSCAD 2024+ (Manifold backend): brew install --cask openscad@snapshot
set -euo pipefail
cd "$(dirname "$0")"

SRC=devin_local_london.scad
scad() {
    local log
    log=$(openscad --backend=manifold "$@" "$SRC" 2>&1) || { echo "$log"; exit 1; }
    if grep -qE "WARNING|ERROR" <<<"$log"; then grep -E "WARNING|ERROR" <<<"$log"; exit 1; fi
}

mkdir -p stl/two_colour images

echo "Exporting STLs..."
scad -D 'part="all"'      -o stl/devin_local_london_keychain.stl
scad -D 'part="all"' -D 'spinner=false' -o stl/devin_local_london_keychain_static.stl
scad -D 'part="base"'     -o stl/two_colour/base.stl
scad -D 'part="accent"'   -o stl/two_colour/accent.stl
scad -D 'part="eye_test"' -o stl/eye_gap_test.stl
scad -D 'part="preview"'  -o stl/two_colour/devin_local_london_keychain_2colour.3mf

echo "Rendering images..."
IMG=(--render --colorscheme=Tomorrow -D 'part="preview"')
scad "${IMG[@]}" --imgsize=2000,1200 --camera=14,-92,120,37.5,23,1.5 -o images/hero.png
scad "${IMG[@]}" --imgsize=2000,1200 --camera=38,21,0,0,0,0,125 --projection=ortho -o images/top.png

scad --render --colorscheme=Tomorrow -D 'part="cutaway"' --imgsize=1600,800 \
    --camera=5,-24,12,11.5,0,1.5 -o images/bearing_section.png

echo "Done."
