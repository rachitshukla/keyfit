#!/bin/sh
# Build all Finder and Retina icon representations from the master PNG.
set -eu
source_png=$1
output_icns=$2
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
iconset="$temp_dir/KeyFit.iconset"
mkdir "$iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$source_png" --out "$iconset/icon_${size}x${size}.png" >/dev/null
    retina=$((size * 2))
    sips -z "$retina" "$retina" "$source_png" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$output_icns"
