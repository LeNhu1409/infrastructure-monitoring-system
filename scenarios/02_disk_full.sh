#!/usr/bin/env bash
# Kịch bản 2: Disk đầy (giả lập, KHÔNG đụng vào ổ đĩa thật của máy).
# Chạy: bash scenarios/02_disk_full.sh [loop|textfile] [số giây, mặc định 300]
#   loop     : tạo ổ ext4 nhỏ 200MB (file .img) gắn vào /mnt rồi lấp đầy ~92%. Cần sudo, Linux/WSL.
#              Chỉ hiển thị được khi Docker chạy trực tiếp trên Linux (không phải Docker Desktop).
#   textfile : ghi metric giả hkdn_sim_disk_used_percent=92 qua textfile collector. Chạy mọi nơi.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MODE="${1:-loop}"
DURATION="${2:-300}"

require_prometheus

if [[ "$MODE" == "loop" ]] && docker info --format '{{.OperatingSystem}}' 2>/dev/null | grep -qi "docker desktop"; then
  echo "Phát hiện Docker Desktop: chế độ loop không hiển thị được trong container, chuyển sang textfile."
  MODE="textfile"
fi

cleanup() { :; }
trap 'cleanup' EXIT

if [[ "$MODE" == "loop" ]]; then
  IMG="/tmp/hkdn-small-disk.img"
  MNT="/mnt/hkdn-small-disk"
  ALERT="DiskSpaceLow"
  cleanup() {
    sudo umount "$MNT" 2>/dev/null || true
    sudo rmdir "$MNT" 2>/dev/null || true
    rm -f "$IMG"
  }
  sudo mkdir -p "$MNT"
  truncate -s 200M "$IMG"
  mkfs.ext4 -q -F -m 0 "$IMG"
  sudo mount -o loop "$IMG" "$MNT"
  log_event "INJECT scenario=disk_full mode=loop mount=$MNT duration=${DURATION}s"
  SIZE_MB="$(df --output=size -BM "$MNT" | tail -1 | tr -dc '0-9')"
  FILL_MB=$(( SIZE_MB * 92 / 100 ))
  sudo fallocate -l "${FILL_MB}M" "$MNT/fill.bin"
elif [[ "$MODE" == "textfile" ]]; then
  PROM_FILE="$SCENARIO_DIR/textfile/sim_disk.prom"
  ALERT="DiskSpaceLowSimulated"
  cleanup() { rm -f "$PROM_FILE" "$PROM_FILE.tmp"; }
  log_event "INJECT scenario=disk_full mode=textfile duration=${DURATION}s"
  printf '# HELP hkdn_sim_disk_used_percent Disk usage percent (simulation)\n# TYPE hkdn_sim_disk_used_percent gauge\nhkdn_sim_disk_used_percent{mountpoint="/sim-data"} 92\n' > "$PROM_FILE.tmp"
  mv "$PROM_FILE.tmp" "$PROM_FILE"
else
  echo "Chế độ không hợp lệ: $MODE (dùng loop hoặc textfile)" >&2
  exit 1
fi

START=$SECONDS
wait_for_alert "$ALERT" "$DURATION" || true
REMAIN=$(( DURATION - (SECONDS - START) ))
if (( REMAIN > 0 )); then sleep "$REMAIN"; fi

cleanup
log_event "RECOVER scenario=disk_full mode=$MODE"
wait_for_resolved "$ALERT" 300 || true
log_event "DONE scenario=disk_full mode=$MODE"
