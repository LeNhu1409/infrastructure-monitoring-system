# Baseline lab N4.7

- Khoảng đo: 2026-11-08 05:56 UTC → 2026-11-09 05:56 UTC (24 giờ), step 15s
- Nguồn: Prometheus http://localhost:9090; biểu thức lấy từ dashboard host-service-overview

## CPU (%)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 5761 | 0.261 | 0.262 | 0.312 | 0.443 | 3.517 |

## RAM (%)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 5761 | 15.383 | 15.646 | 16.150 | 16.443 | 17.091 |

## Disk (%)

| mountpoint | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| /mnt | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/host/wslg/distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt/host/wslg/distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt/host/wslg/distro | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /usr/lib/modules | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /usr/lib/wsl | 5761 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/docker-desktop-disk | 5761 | 7.587 | 7.587 | 7.590 | 7.591 | 7.592 |
| /parent-distro/mnt/docker-desktop-disk | 5761 | 7.587 | 7.587 | 7.590 | 7.591 | 7.592 |
| /run/desktop/mnt/docker-desktop-disk | 5761 | 7.587 | 7.587 | 7.590 | 7.591 | 7.592 |
| /var/lib | 5761 | 7.587 | 7.587 | 7.590 | 7.591 | 7.592 |
| /mnt/host/c | 5761 | 63.988 | 64.536 | 64.551 | 64.559 | 64.559 |
| /parent-distro/mnt/host/c | 5761 | 63.988 | 64.536 | 64.551 | 64.559 | 64.559 |
| /run/desktop/mnt/host/c | 5761 | 63.988 | 64.536 | 64.551 | 64.559 | 64.559 |
| /mnt/host/d | 5761 | 78.779 | 78.806 | 78.909 | 79.245 | 79.245 |
| /parent-distro/mnt/host/d | 5761 | 78.779 | 78.806 | 78.909 | 79.245 | 79.245 |
| /run/desktop/mnt/host/d | 5761 | 78.779 | 78.806 | 78.909 | 79.245 | 79.245 |
| /parent-distro/usr/lib/wsl/drivers | 5761 | 63.988 | 64.536 | 64.551 | 64.559 | 64.559 |
| /usr/lib/wsl/drivers | 5761 | 63.988 | 64.536 | 64.551 | 64.559 | 64.559 |
| /parent-distro/init | 5761 | 0.067 | 0.067 | 0.067 | 0.067 | 0.067 |

## Network nhận (B/s)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 5761 | 41.602 | 41.602 | 41.604 | 41.604 | 42.537 |

## Network gửi (B/s)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 5761 | 1025.360 | 1025.824 | 1028.578 | 1029.379 | 1031.892 |

## Thời gian probe (s)

| service | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| demo-web | 5761 | 0.002 | 0.002 | 0.002 | 0.003 | 0.099 |

## Probe thành công (1=UP)

| service | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| demo-web | 5761 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |

## CPU theo container (%)

| name | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| (không có dữ liệu) | | | | | | |

## RAM theo container (MB)

| name | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| (không có dữ liệu) | | | | | | |
