#!/usr/bin/env bash
# The only privileged command the deploy user may run (see sudoers below).
# Install as root:
#   install -o root -g root -m 0755 individ-deploy.sh /usr/local/sbin/individ-deploy
#   echo 'mistaker0908 ALL=(root) NOPASSWD: /usr/local/sbin/individ-deploy' > /etc/sudoers.d/91-individ-deploy
#   chmod 440 /etc/sudoers.d/91-individ-deploy && visudo -cf /etc/sudoers.d/91-individ-deploy
#
# Usage (archives are uploaded to the deploy user's home first):
#   sudo individ-deploy server ~/srv.tgz      API code (keeps .venv), backup first, restart, health check
#   sudo individ-deploy web ~/web.tgz         site bundle, atomic swap, keeps the previous one
#   sudo individ-deploy migrate ~/NNN_x.sql   run one SQL migration as postgres (after a backup)
#   sudo individ-deploy backup                take a backup now
#   sudo individ-deploy status                service state, health, last errors
set -euo pipefail
umask 027

ROOT=/srv/individ
DEPLOY_HOME=/home/mistaker0908

need_file() {
  local f
  f=$(realpath -e -- "$1")
  # Only archives the deploy user uploaded to their home - nothing else on disk.
  case "$f" in "$DEPLOY_HOME"/*) ;; *) echo "refusing: $f is outside $DEPLOY_HOME" >&2; exit 2 ;; esac
  [ -f "$f" ] || { echo "not a file: $f" >&2; exit 2; }
  printf '%s' "$f"
}

no_links() {
  # An archive must hold only plain files and folders: a symlink or hard link
  # could make the root-run steps below touch files outside the target.
  if tar tvzf "$1" | grep -qE '^[lhcbp]'; then
    echo "refusing: archive contains links or special files" >&2; exit 2
  fi
  if tar tzf "$1" | grep -qE '(^/|(^|/)\.\.(/|$))'; then
    echo "refusing: archive contains absolute or parent paths" >&2; exit 2
  fi
}

health() {
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    # Through nginx like a real visitor: the API only answers HTTPS requests for its own host.
    if curl -fsS --max-time 3 --resolve individ.uz:443:127.0.0.1 https://individ.uz/api/health >/dev/null; then
      echo "health: ok"; return 0
    fi
    sleep 1
  done
  echo "health: FAILED" >&2
  journalctl -u individ-api -n 30 --no-pager >&2
  return 1
}

case "${1:-}" in
  server)
    f=$(need_file "${2:?archive}")
    no_links "$f"
    /usr/local/bin/individ-backup
    tmp=$(mktemp -d)
    tar xzf "$f" -C "$tmp"
    [ -f "$tmp/app/main.py" ] || { echo "archive has no app/main.py" >&2; rm -rf "$tmp"; exit 2; }
    rsync -a --delete --exclude .venv "$tmp"/ "$ROOT/server/"
    rm -rf "$tmp" "$f"
    chown -Rh root:individ "$ROOT/server"
    find "$ROOT/server" -path "$ROOT/server/.venv" -prune -o -type d -exec chmod 750 {} +
    find "$ROOT/server" -path "$ROOT/server/.venv" -prune -o -type f -exec chmod 640 {} +
    systemctl restart individ-api
    health
    ;;
  web)
    f=$(need_file "${2:?archive}")
    no_links "$f"
    new="$ROOT/web.new"
    rm -rf "$new" && mkdir "$new"
    tar xzf "$f" -C "$new"
    for must in index.html main.dart.js assets/AssetManifest.bin.json assets/FontManifest.json; do
      [ -f "$new/$must" ] || { echo "incomplete bundle: $must missing" >&2; rm -rf "$new"; exit 2; }
    done
    find "$new" -type f \( -name '*.js' -o -name '*.json' -o -name '*.html' -o -name '*.css' -o -name '*.wasm' \
      -o -name '*.ttf' -o -name '*.otf' -o -name '*.svg' \) ! -name '*.gz' -exec gzip -kf -9 {} +
    chown -Rh root:www-data "$new"
    find "$new" -type d -exec chmod 750 {} +
    find "$new" -type f -exec chmod 640 {} +
    rm -rf "$ROOT/web.old"
    [ -d "$ROOT/web" ] && mv "$ROOT/web" "$ROOT/web.old"
    mv "$new" "$ROOT/web"
    rm -f "$f"
    echo "web: deployed"
    ;;
  migrate)
    f=$(need_file "${2:?sql file}")
    /usr/local/bin/individ-backup
    sudo -u postgres psql -d individ -v ON_ERROR_STOP=1 -q < "$f"
    rm -f "$f"
    echo "migration applied"
    ;;
  backup)
    /usr/local/bin/individ-backup
    ;;
  status)
    systemctl is-active individ-api nginx postgresql fail2ban || true
    health || true
    journalctl -u individ-api --since "1 hour ago" -p warning --no-pager | tail -10
    ;;
  *)
    echo "usage: individ-deploy server|web|migrate <file> | backup | status" >&2
    exit 2
    ;;
esac
