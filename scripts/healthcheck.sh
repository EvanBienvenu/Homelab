#!/usr/bin/env bash
# healthcheck.sh : vérifie l'état de la machine
# Code de retour : 0 = tout va bien, 1 = au moins un problème
set -uo pipefail
export LC_ALL=C   # sorties des commandes en anglais, donc prévisibles

# Seuils réglables depuis l'extérieur, avec une valeur par défaut
SEUIL_DISQUE="${SEUIL_DISQUE:-80}"    # % d'occupation max de /
SEUIL_MEMOIRE="${SEUIL_MEMOIRE:-90}"  # % de mémoire utilisée max
SERVICES=(systemd-journald systemd-resolved NetworkManager)
URL_TEST="https://github.com"

ECHECS=0
ok() { echo "[OK]     $1"; }
ko() { echo "[ALERTE] $1"; ECHECS=$((ECHECS + 1)); }

# 1. Espace disque de la partition principale
disque=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if (( disque < SEUIL_DISQUE )); then
  ok "disque / utilisé à ${disque} %"
else
  ko "disque / utilisé à ${disque} % (seuil ${SEUIL_DISQUE} %)"
fi

# 2. Mémoire utilisée (total moins disponible)
memoire=$(free | awk '/^Mem:/ {printf "%d", ($2 - $7) * 100 / $2}')
if (( memoire < SEUIL_MEMOIRE )); then
  ok "mémoire utilisée à ${memoire} %"
else
  ko "mémoire utilisée à ${memoire} % (seuil ${SEUIL_MEMOIRE} %)"
fi

# 3. Services essentiels
for service in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$service"; then
    ok "service $service actif"
  else
    ko "service $service inactif"
  fi
done

# 4. Accès réseau sortant
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
