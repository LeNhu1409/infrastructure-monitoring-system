#!/usr/bin/env bash
# vm-db: Redis (cổng 6379, chỉ nghe localhost) + Redis Exporter (cổng 9121).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y redis-server prometheus-redis-exporter
systemctl enable --now redis-server
systemctl enable --now prometheus-redis-exporter
