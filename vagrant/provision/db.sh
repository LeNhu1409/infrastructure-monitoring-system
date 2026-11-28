#!/usr/bin/env bash
# vm-db: Redis + MariaDB (cổng 6379, nghe localhost và IP mạng riêng của lab) + Redis Exporter (cổng 9121).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y redis-server prometheus-redis-exporter
# Cho phép Blackbox (trên máy host) kiểm tra cổng TCP; mạng 192.168.56.0/24 là mạng riêng của lab.
sed -i 's/^bind .*/bind 127.0.0.1 192.168.56.12/' /etc/redis/redis.conf
systemctl enable redis-server
systemctl restart redis-server
systemctl enable --now prometheus-redis-exporter

# MariaDB (cổng 3306): nghe localhost và IP mạng riêng của lab để Blackbox kiểm tra cổng TCP.
apt-get install -y mariadb-server
cat > /etc/mysql/mariadb.conf.d/99-hkdn.cnf <<'CONF'
[mysqld]
bind-address = 192.168.56.12
CONF
systemctl enable mariadb
systemctl restart mariadb
