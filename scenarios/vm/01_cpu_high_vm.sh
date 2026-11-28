#!/usr/bin/env bash
# Kich ban 1 (VM): CPU cao tren vm-web bang stress-ng.
# Chay: bash scenarios/vm/01_cpu_high_vm.sh [so giay, mac dinh 300]

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

VM="vm-web"
DURATION="${1:-300}"

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || (( DURATION < 1 )); then
  echo "Thoi gian phai la so giay duong." >&2
  exit 1
fi

require_prometheus
require_vm "$VM"

cleanup() {
  vm_ssh "$VM" "sudo systemctl stop hkdn-stress.service 2>/dev/null; sudo pkill stress-ng 2>/dev/null; true" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Khoi chay stress-ng tren vm-web.
vm_ssh "$VM" "sudo systemctl stop hkdn-stress.service 2>/dev/null; sudo systemctl reset-failed hkdn-stress.service 2>/dev/null; sudo systemd-run --unit=hkdn-stress --collect stress-ng --cpu 0 --timeout $((DURATION + 3))s" >/dev/null 2>&1

sleep 3

if ! vm_ssh "$VM" "systemctl is-active --quiet hkdn-stress.service" >/dev/null 2>&1; then
  log_event "ERROR stress-ng khong chay tren $VM"
  exit 1
fi

START=$SECONDS
log_event "INJECT scenario=cpu_high vm=$VM duration=${DURATION}s"

if wait_for_alert HighCpuUsage "$DURATION" "$START" 'instance="192.168.56.11:9100"'; then
  DETECTED=1
else
  DETECTED=0
fi

REMAIN=$((DURATION - (SECONDS - START)))
if (( REMAIN > 0 )); then
  sleep "$REMAIN"
fi

cleanup
log_event "RECOVER scenario=cpu_high vm=$VM"

if (( DETECTED )); then
  wait_for_resolved HighCpuUsage 300 'instance="192.168.56.11:9100"' || true
else
  log_event "RESOLUTION_NOT_APPLICABLE alert=HighCpuUsage reason=never_fired"
fi

log_event "DONE scenario=cpu_high vm=$VM"
