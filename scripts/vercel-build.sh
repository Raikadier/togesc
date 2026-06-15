#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$ROOT/flutter/bin:$PATH"

cd "$ROOT/TOGESC/togesc"

DART_DEFINES=()
if [ -n "${SUPABASE_URL:-}" ]; then
  DART_DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
fi
if [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  DART_DEFINES+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
fi

flutter build web --release --no-wasm-dry-run "${DART_DEFINES[@]}"
