#!/usr/bin/env bash
# Cài đặt chung cho mọi VM: Node Exporter (cổng 9100) + stress-ng (dùng cho kịch bản CPU cao).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y prometheus-node-exporter stress-ng
systemctl enable --now prometheus-node-exporter
