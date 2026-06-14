#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/TOGESC/togesc"

../../flutter/bin/flutter build web --release
