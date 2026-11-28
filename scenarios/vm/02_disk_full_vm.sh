#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_vm.sh"

VM="vm-db"
DURATION="${1:-420}"
MOUNT_POINT="/mnt/hkdn-small-disk"
IMAGE="/tmp/hkdn-small-disk.img"
METRIC_DIR="/var/lib/prometheus/node-exporter"
METRIC_FILE="$METRIC_DIR/hkdn_disk.prom"

DETECTED=0

require_prometheus
require_vm "$VM"

cleanup() {
    vm_ssh "$VM" "sudo rm -f $METRIC_FILE; sudo umount $MOUNT_POINT 2>/dev/null || true; sudo rmdir $MOUNT_POINT 2>/dev/null || true; sudo rm -f $IMAGE; true" >/dev/null 2>&1 || true
}

trap cleanup EXIT

# Dá»n dá»¯ liá»‡u thá»­ nghiá»‡m cÅ©
cleanup

# Táº¡o á»• Ä‘Ä©a loop áº£o 200 MB
vm_ssh "$VM" "sudo mkdir -p $MOUNT_POINT && sudo truncate -s 200M $IMAGE && sudo mkfs.ext4 -q -F -m 0 $IMAGE && sudo mount -o loop $IMAGE $MOUNT_POINT"

# Chiáº¿m 92% dung lÆ°á»£ng á»• Ä‘Ä©a
vm_ssh "$VM" "SIZE=\$(df --output=size -BM $MOUNT_POINT | tail -1 | tr -dc 0-9) && sudo fallocate -l \$(( SIZE * 92 / 100 ))M $MOUNT_POINT/fill.bin"

# Ghi metric cho Node Exporter Textfile Collector
vm_ssh "$VM" "PCT=\$(df --output=pcent $MOUNT_POINT | tail -1 | tr -dc 0-9) && echo hkdn_sim_disk_used_percent \$PCT | sudo tee $METRIC_FILE >/dev/null"

# Kiá»ƒm tra metric Ä‘Ã£ Ä‘Æ°á»£c Node Exporter Ä‘á»c
if ! vm_ssh "$VM" "curl -fsS http://localhost:9100/metrics | grep '^hkdn_sim_disk_used_percent '" >/dev/null; then
    log_event "ERROR textfile_metric_not_visible vm=$VM"
    exit 1
fi

START=$SECONDS

log_event "INJECT scenario=disk_full vm=$VM mountpoint=$MOUNT_POINT duration=${DURATION}s"

if wait_for_alert DiskSpaceLowSimulated "$DURATION" "$START"; then
    DETECTED=1
else
    DETECTED=0
fi

# Giá»¯ tÃ¬nh tráº¡ng giáº£ láº­p Ä‘á»§ thá»i gian
REMAIN=$(( DURATION - (SECONDS - START) ))

if (( REMAIN > 0 )); then
    sleep "$REMAIN"
fi

# KhÃ´i phá»¥c á»• Ä‘Ä©a vÃ  xÃ³a metric
cleanup

log_event "RECOVER scenario=disk_full vm=$VM"

if (( DETECTED )); then
    wait_for_resolved DiskSpaceLowSimulated 300 || true
else
    log_event "RESOLUTION_NOT_APPLICABLE alert=DiskSpaceLowSimulated reason=never_fired"
fi

log_event "DONE scenario=disk_full vm=$VM"
