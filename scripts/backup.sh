#!/usr/bin/env bash
# usage : sudo ./scripts/backup.sh [dossier_source] [nombre_a_garder]
set -euo pipefail
umask 077
SOURCE="${1:-/etc}"
A_GARDER="${2:-7}"
DESTINATION="/var/backups/homelab"
PREFIXE="$(basename "$SOURCE")"

log() { echo "$(date '+%F %T') [$1] $2"; }

if [[ $EUID -ne 0 ]]; then
  log ERREUR "lance ce script avec sudo"
  exit 1
fi
if [[ ! -d "$SOURCE" ]]; then
  log ERREUR "dossier source introuvable : $SOURCE"
  exit 1
fi

mkdir -p "$DESTINATION"
ARCHIVE="$DESTINATION/${PREFIXE}-$(date '+%Y%m%d-%H%M%S').tar.gz"
log INFO "sauvegarde de $SOURCE vers $ARCHIVE"
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$PREFIXE"

if tar -tzf "$ARCHIVE" >/dev/null; then
  log OK "archive vérifiée ($(du -h "$ARCHIVE" | cut -f1))"
else
  log ERREUR "archive illisible : $ARCHIVE"
  exit 1
fi

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
log OK "empreinte SHA-256 enregistrée"

# rotation : garde les $A_GARDER plus récentes
mapfile -t ANCIENNES < <(
  find "$DESTINATION" -maxdepth 1 -name "${PREFIXE}-*.tar.gz" -printf '%T@ %p\n' \
    | sort -rn | tail -n +"$((A_GARDER + 1))" | cut -d' ' -f2-
)
for ancienne in "${ANCIENNES[@]}"; do
  rm -f -- "$ancienne" "$ancienne.sha256"
  log INFO "supprimée par rotation : $(basename "$ancienne")"
done

NB=$(find "$DESTINATION" -maxdepth 1 -name "${PREFIXE}-*.tar.gz" | wc -l)
log OK "sauvegarde terminée, $NB archive(s) conservée(s)"
