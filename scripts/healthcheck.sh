#!/usr/bin/env bash
# code retour : 0 = ok, 1 = au moins un problème
set -uo pipefail
export LC_ALL=C   # sorties en anglais pour le parsing

SEUIL_DISQUE="${SEUIL_DISQUE:-80}"
SEUIL_MEMOIRE="${SEUIL_MEMOIRE:-90}"
SERVICES=(systemd-journald systemd-resolved NetworkManager)
URL_TEST="https://github.com"

ECHECS=0
ok() { echo "[OK]     $1"; }
ko() { echo "[ALERTE] $1"; ECHECS=$((ECHECS + 1)); }

disque=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if (( disque < SEUIL_DISQUE )); then
  ok "disque / utilisé à ${disque} %"
else
  ko "disque / utilisé à ${disque} % (seuil ${SEUIL_DISQUE} %)"
fi

memoire=$(free | awk '/^Mem:/ {printf "%d", ($2 - $7) * 100 / $2}')
if (( memoire < SEUIL_MEMOIRE )); then
  ok "mémoire utilisée à ${memoire} %"
else
  ko "mémoire utilisée à ${memoire} % (seuil ${SEUIL_MEMOIRE} %)"
fi

for service in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$service"; then
    ok "service $service actif"
  else
    ko "service $service inactif"
  fi
done

if curl -sSf --max-time 5 -o /dev/null "$URL_TEST"; then
  ok "accès à $URL_TEST"
else
  ko "pas d'accès à $URL_TEST"
fi

echo "---"
if (( ECHECS == 0 )); then
  echo "Bilan : tout va bien"
  exit 0
else
  echo "Bilan : $ECHECS problème(s) détecté(s)"
  exit 1
fi
