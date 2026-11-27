#!/usr/bin/env bash
# vm-web: dịch vụ web nginx (cổng 80).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y nginx
echo "<h1>vm-web - HKDN N4.7 lab</h1>" > /var/www/html/index.html
systemctl enable --now nginx
