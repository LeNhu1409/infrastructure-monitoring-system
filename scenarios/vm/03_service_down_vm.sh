#!/usr/bin/env bash
# Kịch bản 3 (VM): dừng một dịch vụ trên máy ảo (mặc định nginx trên vm-web).
# Chạy: bash scenarios/vm/03_service_down_vm.sh [số giây, mặc định 120] [vm] [dịch vụ systemd]
# Ví dụ dừng API Python: bash scenarios/vm/03_service_down_vm.sh 120 vm-app hkdn-api
# Lưu ý: luật ServiceDown hiện chỉ xét HTTP (nginx, api). MariaDB/Redis là kiểm tra TCP, cần đổi luật (xem docs/vm-environment.md).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

DURATION="${1:-120}"
VM="${2:-vm-web}"
SVC="${3:-nginx}"
require_prometheus
require_vm "$VM"

cleanup() { vm_ssh "$VM" "sudo systemctl start $SVC" >/dev/null 2>&1 || true; }
trap cleanup EXIT

log_event "INJECT scenario=service_down vm=$VM service=$SVC duration=${DURATION}s"
vm_ssh "$VM" "sudo systemctl stop $SVC" >/dev/null

START=$SECONDS
wait_for_alert ServiceDown "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=service_down vm=$VM"
wait_for_resolved ServiceDown 300 || true
log_event "DONE scenario=service_down vm=$VM"
