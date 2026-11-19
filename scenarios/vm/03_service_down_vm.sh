#!/usr/bin/env bash
# Kịch bản 3 (VM): dừng một dịch vụ trên máy ảo.
# Chạy: bash scenarios/vm/03_service_down_vm.sh [số giây] [vm] [dịch vụ systemd]

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

DURATION="${1:-120}"
VM="${2:-vm-web}"
SVC="${3:-nginx}"

require_prometheus
require_vm "$VM"

cleanup() {
  vm_ssh "$VM" "sudo systemctl start $SVC" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Dừng dịch vụ trước. Nếu thao tác thất bại, không ghi nhận INJECT.
vm_ssh "$VM" "sudo systemctl stop $SVC" >/dev/null

# Bắt đầu đo sau khi dịch vụ đã được dừng.
START=$SECONDS
log_event "INJECT scenario=service_down vm=$VM service=$SVC duration=${DURATION}s"

if wait_for_alert ServiceDown "$DURATION" "$START"; then
  DETECTED=1
else
  DETECTED=0
fi

REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then
  sleep "$REMAIN"
fi

cleanup
log_event "RECOVER scenario=service_down vm=$VM"

if (( DETECTED )); then
  wait_for_resolved ServiceDown 300 || true
else
  log_event "RESOLUTION_NOT_APPLICABLE alert=ServiceDown reason=never_fired"
fi

log_event "DONE scenario=service_down vm=$VM"
