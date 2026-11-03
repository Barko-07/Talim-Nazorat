#!/usr/bin/env bash
# Daily encrypted database backup. Install as root:
#   cp backup.sh /usr/local/bin/individ-backup && chmod 700 /usr/local/bin/individ-backup
#   echo '30 2 * * * root /usr/local/bin/individ-backup' > /etc/cron.d/individ-backup
# The backup is encrypted with the PUBLIC key in /etc/individ/backup.pub (age).
# Keep the matching private key OFF the server - then a stolen server cannot read backups.
set -euo pipefail
umask 077

OUT=/var/backups/individ
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
FILE="$OUT/individ-$STAMP.sql.gz.age"

sudo -u postgres pg_dump --no-owner --format=plain individ \
  | gzip -9 \
  | age -R /etc/individ/backup.pub > "$FILE"

# Keep 30 days locally; copy offsite (another server / object storage in Uzbekistan).
find "$OUT" -name 'individ-*.sql.gz.age' -mtime +30 -delete
echo "backup written: $FILE"
