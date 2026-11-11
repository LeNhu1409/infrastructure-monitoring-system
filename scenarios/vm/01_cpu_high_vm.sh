#!/usr/bin/env bash
# Kịch bản 1 (VM): CPU cao trên vm-web bằng stress-ng.
# Chạy: bash scenarios/vm/01_cpu_high_vm.sh [số giây, mặc định 300]
# Thử cảnh báo giả: chạy với số giây ngắn hơn "for" của luật (ví dụ 30).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

VM="vm-web"
DURATION="${1:-300}"
require_prometheus
require_vm "$VM"

cleanup() { vm_ssh "$VM" "sudo pkill stress-ng || true" >/dev/null 2>&1 || true; }
trap cleanup EXIT

log_event "INJECT scenario=cpu_high vm=$VM duration=${DURATION}s"
vm_ssh "$VM" "nohup sudo stress-ng --cpu 1 --timeout ${DURATION}s >/dev/null 2>&1 &" >/dev/null

START=$SECONDS
wait_for_alert HighCpuUsage "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=cpu_high vm=$VM"
wait_for_resolved HighCpuUsage 300 || true
log_event "DONE scenario=cpu_high vm=$VM"
