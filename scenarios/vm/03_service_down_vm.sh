#!/usr/bin/env bash
# Kịch bản 3 (VM): dừng nginx trên vm-web.
# Chạy: bash scenarios/vm/03_service_down_vm.sh [số giây, mặc định 120]
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

VM="vm-web"
DURATION="${1:-120}"
require_prometheus
require_vm "$VM"

cleanup() { vm_ssh "$VM" "sudo systemctl start nginx" >/dev/null 2>&1 || true; }
trap cleanup EXIT

log_event "INJECT scenario=service_down vm=$VM service=nginx duration=${DURATION}s"
vm_ssh "$VM" "sudo systemctl stop nginx" >/dev/null

START=$SECONDS
wait_for_alert ServiceDown "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=service_down vm=$VM"
wait_for_resolved ServiceDown 300 || true
log_event "DONE scenario=service_down vm=$VM"
