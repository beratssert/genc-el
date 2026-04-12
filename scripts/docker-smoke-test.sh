#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "[docker-smoke] .env dosyasi bulunamadi. Once .env olusturun."
  exit 1
fi

cleanup() {
  echo "[docker-smoke] Docker compose kapatiliyor..."
  docker compose down -v || true
}
trap cleanup EXIT

echo "[docker-smoke] Servisler ayaga kaldiriliyor..."
docker compose up -d --build

echo "[docker-smoke] API login endpoint'i bekleniyor..."
for i in {1..60}; do
  if curl -sS -m 5 -X POST "http://localhost:8080/api/v1/admin/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"superadmin@gencel.com","password":"superadmin123"}' \
    | grep -q '"token"'; then
    echo "[docker-smoke] Basarili: token dondu."
    exit 0
  fi

  sleep 2
  echo "[docker-smoke] Bekleniyor... deneme $i/60"
done

echo "[docker-smoke] HATA: API beklenen surede hazir olmadi veya login basarisiz."
docker compose logs backend | tail -n 200 || true
exit 1
