#!/usr/bin/env bash
# Kịch bản 3: Dịch vụ down (dừng container demo-web).
# Chạy: bash scenarios/03_service_down.sh [số giây, mặc định 120]
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CONTAINER="hkdn-demo-web"
DURATION="${1:-120}"

require_prometheus

cleanup() { docker start "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

log_event "INJECT scenario=service_down container=${CONTAINER} duration=${DURATION}s"
docker stop "$CONTAINER" >/dev/null

START=$SECONDS
wait_for_alert ServiceDown "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=service_down"
wait_for_resolved ServiceDown 300 || true
log_event "DONE scenario=service_down"
