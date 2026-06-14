#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -d flutter ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  (
    cd flutter
    git fetch --depth 1 origin stable
    git checkout stable
    git pull --ff-only origin stable
  )
fi

./flutter/bin/flutter config --enable-web
./flutter/bin/flutter --version

cd TOGESC/togesc
../../flutter/bin/flutter pub get
