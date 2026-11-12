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

cleanup() { vm_ssh "$VM" "sudo systemctl stop hkdn-stress.service 2>/dev/null; sudo pkill stress-ng; true" >/dev/null 2>&1 || true; }
trap cleanup EXIT

log_event "INJECT scenario=cpu_high vm=$VM duration=${DURATION}s"
# Chạy stress-ng như một dịch vụ systemd để không bị tắt khi phiên SSH đóng; --cpu 0 = dùng hết mọi core.
vm_ssh "$VM" "sudo systemctl stop hkdn-stress.service 2>/dev/null; sudo systemctl reset-failed hkdn-stress.service 2>/dev/null; sudo systemd-run --unit=hkdn-stress --collect stress-ng --cpu 0 --timeout ${DURATION}s" >/dev/null 2>&1
sleep 3
if ! vm_ssh "$VM" "systemctl is-active --quiet hkdn-stress.service" >/dev/null 2>&1; then
  log_event "ERROR stress-ng không chạy trên $VM, kịch bản dừng"
  exit 1
fi

START=$SECONDS
wait_for_alert HighCpuUsage "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=cpu_high vm=$VM"
wait_for_resolved HighCpuUsage 300 || true
log_event "DONE scenario=cpu_high vm=$VM"
