#!/usr/bin/env bash
# Kịch bản 1 (VM): CPU cao trên vm-web bằng stress-ng.
# Chạy: bash scenarios/vm/01_cpu_high_vm.sh [số giây, mặc định 300]

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

VM="vm-web"
DURATION="${1:-300}"

require_prometheus
require_vm "$VM"

cleanup() {
  vm_ssh "$VM" "sudo systemctl stop hkdn-stress.service 2>/dev/null; sudo pkill stress-ng; true" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Khởi chạy stress-ng; cộng 3 giây để dành cho bước xác nhận dịch vụ.
vm_ssh "$VM" "sudo systemctl stop hkdn-stress.service 2>/dev/null; sudo systemctl reset-failed hkdn-stress.service 2>/dev/null; sudo systemd-run --unit=hkdn-stress --collect stress-ng --cpu 0 --timeout $((DURATION + 3))s" >/dev/null 2>&1

sleep 3

if ! vm_ssh "$VM" "systemctl is-active --quiet hkdn-stress.service" >/dev/null 2>&1; then
  log_event "ERROR stress-ng không chạy trên $VM, kịch bản dừng"
  exit 1
fi

# Chỉ bắt đầu đo sau khi tải CPU đã thực sự chạy.
START=$SECONDS
log_event "INJECT scenario=cpu_high vm=$VM duration=${DURATION}s"

if wait_for_alert HighCpuUsage "$DURATION" "$START"; then
  DETECTED=1
else
  DETECTED=0
fi

REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then
  sleep "$REMAIN"
fi

cleanup
log_event "RECOVER scenario=cpu_high vm=$VM"

if (( DETECTED )); then
  wait_for_resolved HighCpuUsage 300 || true
else
  log_event "RESOLUTION_NOT_APPLICABLE alert=HighCpuUsage reason=never_fired"
fi

log_event "DONE scenario=cpu_high vm=$VM"
