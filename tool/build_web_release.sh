#!/usr/bin/env bash
# The ONLY way to build the individ.uz web bundle. Builds, checks, and opens the
# result in a real browser under the production Content Security Policy before
# packing it. Refuses to produce an archive if any check fails.
#
#   bash tool/build_web_release.sh          -> build/web_release.tgz
#   (then upload ~/web.tgz and: sudo individ-deploy web ~/web.tgz)
#
# Why each flag:
#   --no-web-resources-cdn  CanvasKit from our server; the CSP blocks gstatic.com,
#                           without it the site is a blank white page (2026-11-07).
#   SERVER_MODE=true        all work data on the server, nothing on the device.
#   --output build/web_server  never build/web (Flutter's own folder; broke prod 2026-11-05).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/web_server
ARCHIVE=build/web_release.tgz

# The screens that talk to the server must work against a fake server first.
flutter test --dart-define=SERVER_MODE=true test/server_sync_test.dart test/server_mode_screens_test.dart   || { echo "BUILD REFUSED: server-mode tests failed" >&2; exit 1; }

flutter build web --release --no-web-resources-cdn --dart-define=SERVER_MODE=true --output "$OUT"

fail() { echo "BUILD REFUSED: $1" >&2; rm -f "$ARCHIVE"; exit 1; }

for f in index.html main.dart.js flutter_bootstrap.js assets/AssetManifest.bin.json \
         assets/FontManifest.json canvaskit/canvaskit.wasm robots.txt sitemap.xml account-deletion.html about.html splash.js; do
  [ -f "$OUT/$f" ] || fail "$f missing"
done
grep -q '"useLocalCanvasKit":true' "$OUT/flutter_bootstrap.js" || fail "CanvasKit would load from gstatic.com"

# The privacy policy is published only once the operator details are filled in.
if grep -q '{{' "$OUT/privacy.html" 2>/dev/null; then
  rm -f "$OUT/privacy.html"
  sed -i '/privacy.html/d' "$OUT/sitemap.xml"
  echo "note: privacy.html has unfilled {{...}} fields - left out of this release"
fi

# Open it in Chromium with the production CSP; the Flutter view must appear.
python "$(dirname "$0")/check_web_bundle.py" "$OUT" server/deploy/nginx/individ_headers.conf \
  || fail "the page does not start under the production CSP"

tar czf "$ARCHIVE" --exclude='*.gz' -C "$OUT" .
echo "OK: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
