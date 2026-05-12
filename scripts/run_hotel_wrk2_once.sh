#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-hotel_wrk2_$(date +%Y%m%d_%H%M%S)}"

NAMESPACE="${NAMESPACE:-hotel-res}"
RPS="${RPS:-10}"
DURATION="${DURATION:-2m}"
THREADS="${THREADS:-2}"
CONNECTIONS="${CONNECTIONS:-16}"

WRK_BIN="${WRK_BIN:-tools/wrk2/wrk}"
LUA_SCRIPT="${LUA_SCRIPT:-hotelReservation/wrk2/scripts/hotel-reservation/mixed-workload_k8s.lua}"

if [ ! -x "$WRK_BIN" ]; then
  echo "ERROR: wrk2 binary not found at $WRK_BIN"
  echo "Build it with: make -C tools/wrk2"
  exit 1
fi

if [ ! -f "$LUA_SCRIPT" ]; then
  echo "ERROR: Lua script not found: $LUA_SCRIPT"
  exit 1
fi

if [ -z "${FRONT_URL:-}" ]; then
  FRONT_IP="$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')"
  FRONT_URL="http://${FRONT_IP}:5000"
fi

OUT_DIR="results/hotel/wrk2/${RUN_ID}"
mkdir -p "$OUT_DIR"

echo "============================================================"
echo "Hotel Reservation wrk2 run"
echo "Run ID      : $RUN_ID"
echo "Namespace   : $NAMESPACE"
echo "Frontend URL: $FRONT_URL"
echo "RPS         : $RPS"
echo "Duration    : $DURATION"
echo "Threads     : $THREADS"
echo "Connections : $CONNECTIONS"
echo "Lua script  : $LUA_SCRIPT"
echo "Output dir  : $OUT_DIR"
echo "============================================================"

kubectl get pods -n "$NAMESPACE" -o wide > "$OUT_DIR/pods_before.txt"
kubectl get svc -n "$NAMESPACE" -o wide > "$OUT_DIR/services_before.txt"

if command -v linkerd >/dev/null 2>&1; then
  linkerd viz stat deploy -n "$NAMESPACE" > "$OUT_DIR/linkerd_before.txt" || true
fi

"$WRK_BIN" \
  -t "$THREADS" \
  -c "$CONNECTIONS" \
  -d "$DURATION" \
  -L \
  -s "$LUA_SCRIPT" \
  "$FRONT_URL" \
  -R "$RPS" \
  | tee "$OUT_DIR/wrk2.log"

kubectl get pods -n "$NAMESPACE" -o wide > "$OUT_DIR/pods_after.txt"

if command -v linkerd >/dev/null 2>&1; then
  linkerd viz stat deploy -n "$NAMESPACE" > "$OUT_DIR/linkerd_after.txt" || true
fi

echo "Saved results in: $OUT_DIR"
