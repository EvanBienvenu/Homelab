#!/usr/bin/env bash
# backup.sh : sauvegarde horodatée d'un dossier, avec vérification et rotation
# Usage : sudo ./scripts/backup.sh [dossier_source] [nombre_a_garder]
set -euo pipefail

SOURCE="${1:-/etc}"
A_GARDER="${2:-7}"
DESTINATION="/var/backups/homelab"
PREFIXE="$(basename "$SOURCE")"

log() { echo "$(date '+%F %T') [$1] $2"; }

# Contrôles avant de commencer
if [[ $EUID -ne 0 ]]; then
  log ERREUR "lance ce script avec sudo"
  exit 1
fi
if [[ ! -d "$SOURCE" ]]; then
  log ERREUR "dossier source introuvable : $SOURCE"
  exit 1
fi

# 1. Création de l'archive datée
mkdir -p "$DESTINATION"
ARCHIVE="$DESTINATION/${PREFIXE}-$(date '+%Y%m%d-%H%M%S').tar.gz"
log INFO "sauvegarde de $SOURCE vers $ARCHIVE"
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$PREFIXE"

# 2. Vérification : une sauvegarde illisible ne sert à rien
if tar -tzf "$ARCHIVE" >/dev/null; then
  log OK "archive vérifiée ($(du -h "$ARCHIVE" | cut -f1))"
else
  log ERREUR "archive illisible : $ARCHIVE"
  exit 1
fi

# 3. Empreinte SHA-256 pour contrôler l'intégrité plus tard
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
log OK "empreinte SHA-256 enregistrée"

# 4. Rotation : on ne garde que les A_GARDER archives les plus récentes
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
