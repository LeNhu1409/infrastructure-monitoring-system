#!/usr/bin/env bash
# Cài đặt chung cho mọi VM: Node Exporter (cổng 9100) + stress-ng (dùng cho kịch bản CPU cao).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y prometheus-node-exporter stress-ng

# Bản Node Exporter của Ubuntu mặc định BỎ QUA các mountpoint dưới /mnt và /media.
# Kịch bản disk đầy (scenarios/vm/02_disk_full_vm.sh) gắn ổ thử tại /mnt/hkdn-small-disk,
# nên bỏ "mnt|media" khỏi danh sách loại trừ để ổ này được báo về Prometheus.
cat > /etc/default/prometheus-node-exporter <<'CONF'
ARGS="--collector.filesystem.mount-points-exclude=^/(dev|proc|run|sys|var/lib/docker/.+)($|/)"
CONF
systemctl enable prometheus-node-exporter
systemctl restart prometheus-node-exporter
