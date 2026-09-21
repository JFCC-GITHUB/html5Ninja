#!/bin/bash
set -e

export PATH="$HOME/.local/bin:$PATH"

echo "Building Godot HTML5 export..."
godot --headless --path godot_project --export-release "Web" ../index.html

echo "Build successful! Exported files in root directory:"
ls -la index.html index.js index.wasm index.pck
