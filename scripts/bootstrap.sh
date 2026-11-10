#!/usr/bin/env bash
set -euo pipefail

PAQUETS=(git curl python3-venv shellcheck jq tree)

log() { echo "$(date '+%F %T') [$1] $2"; }

if [[ $EUID -ne 0 ]]; then
  log ERREUR "lance ce script avec sudo"
  exit 1
fi

A_INSTALLER=()
for paquet in "${PAQUETS[@]}"; do
  if dpkg -s "$paquet" &>/dev/null; then
    log OK "$paquet déjà installé"
  else
    A_INSTALLER+=("$paquet")
  fi
done

if (( ${#A_INSTALLER[@]} > 0 )); then
  log INFO "installation de : ${A_INSTALLER[*]}"
  apt-get update -qq
  apt-get install -y -qq "${A_INSTALLER[@]}"
else
  log INFO "rien à installer"
fi

log OK "bootstrap terminé"
