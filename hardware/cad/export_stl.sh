#!/usr/bin/env bash
# ============================================================
# Export one STL per printable component of the Exacto sight.
#
#   ./export_stl.sh            # export every component
#   ./export_stl.sh top lid    # export only the named components
#
# Output goes to ./stl/ as sight_<component>.stl
# Requires: openscad on PATH.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

SCAD="sight_housing.scad"
OUT="stl"
mkdir -p "$OUT"

# component -> the `part` value passed to the model
ALL=(top bottom bar lid)

# Use the args if given, otherwise export everything.
COMPONENTS=("$@")
if [ "${#COMPONENTS[@]}" -eq 0 ]; then
  COMPONENTS=("${ALL[@]}")
fi

if ! command -v openscad >/dev/null 2>&1; then
  echo "error: openscad not found on PATH" >&2
  exit 1
fi

echo "Exporting ${#COMPONENTS[@]} component(s) from $SCAD -> $OUT/"
for p in "${COMPONENTS[@]}"; do
  out="$OUT/sight_${p}.stl"
  printf '  %-8s -> %s\n' "$p" "$out"
  openscad --export-format binstl -o "$out" -D "part=\"$p\"" "$SCAD"
done
echo "Done."
