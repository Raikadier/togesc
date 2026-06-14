#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -d flutter ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$ROOT/flutter/bin:$PATH"
flutter config --enable-web
flutter --version

cd TOGESC/togesc
flutter pub get
