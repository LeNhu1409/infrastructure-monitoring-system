#!/usr/bin/env bash
# Kịch bản 1: CPU cao.
# Chạy: bash scenarios/01_cpu_high.sh [số giây, mặc định 300]
# Mẹo: chạy với thời gian ngắn hơn "for" của luật (ví dụ 30 giây) để thử trường hợp
# tăng đột biến ngắn -> cảnh báo KHÔNG được firing (minh họa lọc cảnh báo giả).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DURATION="${1:-300}"
NAME="hkdn-stress-cpu"
CORES="$(nproc 2>/dev/null || echo 2)"

require_prometheus

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

log_event "INJECT scenario=cpu_high duration=${DURATION}s cores=${CORES}"
docker run -d --name "$NAME" alpine:3.20 \
  sh -c "for i in \$(seq ${CORES}); do (while :; do :; done) & done; wait" >/dev/null

START=$SECONDS
wait_for_alert HighCpuUsage "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=cpu_high"
wait_for_resolved HighCpuUsage 300 || true
log_event "DONE scenario=cpu_high"
