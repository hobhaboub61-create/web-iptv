#!/bin/bash
set -e

ROOT="/home/uhxc170nab72/iptv-web"
LOG="/tmp/vite.log"
PORT=4173
HOST="135.225.88.163"

echo "[IPTV] Arret des anciens processus..."
pkill -f "node.*vite" 2>/dev/null || true
sleep 1

echo "[IPTV] Verification dependances..."
cd "$ROOT"
if [ ! -d "node_modules" ]; then
  echo "[IPTV] node_modules manquant -> npm install"
  npm install
fi

echo "[IPTV] Build production..."
npm run build

echo "[IPTV] Verification certificat SSL..."
if [ ! -f "certs/cert.pem" ] || [ ! -f "certs/key.pem" ]; then
  echo "[IPTV] Generation certificat auto-signe..."
  mkdir -p certs
  openssl req -x509 -newkey rsa:2048 \
    -keyout certs/key.pem -out certs/cert.pem \
    -days 365 -nodes \
    -subj "/CN=$HOST"
fi

echo "[IPTV] Demarrage serveur Vite (HTTPS, port $PORT)..."
nohup npx vite --host 0.0.0.0 --port "$PORT" > "$LOG" 2>&1 &
VITE_PID=$!

echo "[IPTV] Attente demarrage..."
for i in $(seq 1 10); do
  sleep 1
  if ss -tlnp | grep -q ":$PORT"; then
    echo "[IPTV] ✓ Serveur lancé (PID $VITE_PID)"
    echo "[IPTV] ✓ https://$HOST:$PORT/"
    break
  fi
  if [ "$i" = "10" ]; then
    echo "[IPTV] ✗ ECHEC: Port $PORT pas ouvert"
    tail -20 "$LOG"
    exit 1
  fi
done

echo "[IPTV] Verification HTTP..."
HEALTH=$(curl -skI "https://localhost:$PORT/" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")
if [ "$HEALTH" = "200" ]; then
  echo "[IPTV] ✓ Site repond HTTP $HEALTH"
else
  echo "[IPTV] ✗ Site repond HTTP $HEALTH"
  tail -20 "$LOG"
fi

echo "[IPTV] Logs: tail -f $LOG"
