# Offsite copy of the Individ database backups, run daily on the owner's computer
# (Windows Task Scheduler, task "Individ backup pull").
#
# - Downloads new encrypted backups from the server (~/offsite) over SSH.
# - Proves each new file can actually be restored: decrypts it in memory with
#   the private key and checks the SQL dump is complete. Nothing decrypted is
#   written to disk.
# - Keeps 90 days. Writes a log next to the backups.
#
# The private key (backup-key.txt) never leaves this computer. Keep a second
# copy of it offline (USB stick in a safe): without it no backup can be read.
$ErrorActionPreference = 'Stop'

$Server  = 'mistaker0908@170.168.60.195'
$KeyFile = Join-Path $env:USERPROFILE '.ssh\individ_server'
$AgeKey  = Join-Path $env:USERPROFILE '.individ\backup-key.txt'
$Dest    = Join-Path $env:USERPROFILE '.individ\backups'
$Log     = Join-Path $Dest 'pull.log'
$Age     = (Get-Command age.exe -ErrorAction SilentlyContinue).Source
if (-not $Age) { $Age = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\age.exe' }

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
function Write-Log($msg) { "$(Get-Date -Format s)  $msg" | Out-File -FilePath $Log -Append -Encoding utf8 }

try {
    $remote = & ssh -i $KeyFile -o BatchMode=yes -o ConnectTimeout=20 $Server 'ls -1 ~/offsite' 2>$null
    if ($LASTEXITCODE -ne 0) { throw "server not reachable (ssh exit $LASTEXITCODE)" }
    $new = @($remote | Where-Object { $_ -match '^individ-\d{8}T\d{6}Z\.sql\.gz\.age$' -and -not (Test-Path (Join-Path $Dest $_)) })
    foreach ($name in $new) {
        $target = Join-Path $Dest $name
        & scp -q -i $KeyFile -o BatchMode=yes "${Server}:offsite/$name" "$target.part"
        if ($LASTEXITCODE -ne 0) { throw "download failed: $name" }

        # Restore check: decrypt -> gunzip -> look for the end-of-dump marker.
        $check = & python -c @"
import gzip, subprocess, sys
raw = subprocess.run([sys.argv[1], '-d', '-i', sys.argv[2], sys.argv[3]], capture_output=True, check=True).stdout
sql = gzip.decompress(raw).decode('utf-8', 'replace')
ok = 'PostgreSQL database dump complete' in sql and 'CREATE TABLE public.users' in sql
print('OK' if ok else 'BAD', len(sql))
"@ $Age $AgeKey "$target.part"
        if ($LASTEXITCODE -ne 0 -or -not ($check -like 'OK*')) {
            Remove-Item "$target.part" -ErrorAction SilentlyContinue
            throw "restore check failed for $name ($check)"
        }
        Move-Item "$target.part" $target
        Write-Log "pulled $name, restore check $check"
    }
    if ($new.Count -eq 0) { Write-Log 'nothing new' }

    Get-ChildItem $Dest -Filter 'individ-*.sql.gz.age' |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } |
        Remove-Item
    $latest = Get-ChildItem $Dest -Filter 'individ-*.sql.gz.age' | Sort-Object Name -Descending | Select-Object -First 1
    if ($latest -and $latest.LastWriteTime -lt (Get-Date).AddDays(-3)) {
        Write-Log "WARNING: newest offsite backup is older than 3 days ($($latest.Name))"
    }
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
