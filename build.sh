#!/bin/bash
set -e

export PATH="$HOME/.local/bin:$PATH"

echo "Building Godot HTML5 export..."
godot --headless --path godot_project --export-release "Web" ../index.html

# Cache-bust the main pack: GitHub Pages lets browsers cache assets for ~10 minutes,
# so a stale index.pck could be paired with new code. Version the URL by content hash.
HASH=$(md5sum index.pck | cut -c1-8)
python3 - "$HASH" <<'PY'
import sys
h = sys.argv[1]
s = open('index.html').read()
old = '"fileSizes":{"index.pck":'
assert old in s, 'fileSizes entry not found in index.html'
s = s.replace(old, '"mainPack":"index.pck?v=%s","fileSizes":{"index.pck?v=%s":' % (h, h), 1)
open('index.html', 'w').write(s)
PY

echo "Build successful! Exported files in root directory:"
ls -la index.html index.js index.wasm index.pck
