#!/usr/bin/env bash
# Kịch bản 2 (VM): disk đầy GIẢ LẬP trên vm-db bằng ổ loop 200MB (không đụng ổ hệ thống của VM).
# Chạy: bash scenarios/vm/02_disk_full_vm.sh [số giây, mặc định 420]
# Cần luật DiskSpaceLow đã được bật trong config/alert.rules.yml.
# Mặc định 420 giây vì luật disk có for: 5m (cần lớn hơn 5 phút mới kịp firing).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

VM="vm-db"
DURATION="${1:-420}"
require_prometheus
require_vm "$VM"

cleanup() {
  vm_ssh "$VM" "sudo umount /mnt/hkdn-small-disk 2>/dev/null; sudo rmdir /mnt/hkdn-small-disk 2>/dev/null; rm -f /tmp/hkdn-small-disk.img; true" >/dev/null 2>&1 || true
}
trap cleanup EXIT

log_event "INJECT scenario=disk_full vm=$VM duration=${DURATION}s"
vm_ssh "$VM" "sudo mkdir -p /mnt/hkdn-small-disk && truncate -s 200M /tmp/hkdn-small-disk.img && mkfs.ext4 -q -F -m 0 /tmp/hkdn-small-disk.img && sudo mount -o loop /tmp/hkdn-small-disk.img /mnt/hkdn-small-disk && SIZE=\$(df --output=size -BM /mnt/hkdn-small-disk | tail -1 | tr -dc 0-9) && sudo fallocate -l \$(( SIZE * 92 / 100 ))M /mnt/hkdn-small-disk/fill.bin" >/dev/null

START=$SECONDS
wait_for_alert DiskSpaceLow "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=disk_full vm=$VM"
wait_for_resolved DiskSpaceLow 300 || true
log_event "DONE scenario=disk_full vm=$VM"
