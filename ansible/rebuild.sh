#!/usr/bin/env bash
set -euo pipefail

INSTANCE="app1"
IMAGE="ubuntu-2604"
PORT=8000

cd "$(dirname "$0")"

if incus info "$INSTANCE" > /dev/null 2>&1; then
    echo "==> Suppression de $INSTANCE"
    incus delete --force "$INSTANCE"
fi

echo "==> Création de $INSTANCE"
incus launch "$IMAGE" "$INSTANCE"

echo "==> Attente du réseau dans $INSTANCE"
ready=false
for _ in $(seq 1 30); do
    if incus exec "$INSTANCE" -- getent hosts archive.ubuntu.com > /dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 2
done
if [ "$ready" != true ]; then
    echo "Erreur : pas de réseau dans $INSTANCE" >&2
    exit 1
fi

echo "==> Configuration avec Ansible"
ansible-playbook site.yml

IP=$(incus list "$INSTANCE" -c 4 -f csv | cut -d' ' -f1)
echo "==> Test de l'API sur $IP:$PORT"
curl -fsS --retry 10 --retry-connrefused --retry-delay 2 "http://$IP:$PORT/health"
echo
