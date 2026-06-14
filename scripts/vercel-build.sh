#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$ROOT/flutter/bin:$PATH"

cd "$ROOT/TOGESC/togesc"
flutter build web --release --no-wasm-dry-run
