#!/usr/bin/env bash
set -e

if [ -f "build/web/main.dart.js" ] && ! command -v flutter &> /dev/null; then
  echo "Pre-built build/web detected; using existing web bundle..."
  exit 0
fi

if ! command -v flutter &> /dev/null; then
  echo "Installing Flutter SDK for Vercel build..."
  if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
  fi
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter config --enable-web
flutter pub get
flutter build web --release --pwa-strategy=none --dart-define=DEMO_MODE=true

