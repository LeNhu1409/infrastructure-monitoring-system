# Baseline lab N4.7

- Khoảng đo: 2026-11-04 15:40 UTC → 2026-11-05 15:40 UTC (24 giờ), step 15s
- Nguồn: Prometheus http://localhost:9090; biểu thức lấy từ dashboard host-service-overview

## CPU (%)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 1261 | 0.360 | 0.245 | 0.289 | 0.360 | 49.987 |

## RAM (%)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 1279 | 13.212 | 13.380 | 13.672 | 13.811 | 14.070 |

## Disk (%)

| mountpoint | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| /mnt | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/host/wslg/distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt/host/wslg/distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt/host/wslg/distro | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /usr/lib/modules | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /usr/lib/wsl | 1279 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/docker-desktop-disk | 1279 | 7.576 | 7.576 | 7.577 | 7.577 | 7.577 |
| /parent-distro/mnt/docker-desktop-disk | 1279 | 7.576 | 7.576 | 7.577 | 7.577 | 7.577 |
| /run/desktop/mnt/docker-desktop-disk | 1279 | 7.576 | 7.576 | 7.577 | 7.577 | 7.577 |
| /var/lib | 1279 | 7.576 | 7.576 | 7.577 | 7.577 | 7.577 |
| /mnt/host/c | 1279 | 62.824 | 62.822 | 62.918 | 62.926 | 62.929 |
| /parent-distro/mnt/host/c | 1279 | 62.824 | 62.822 | 62.918 | 62.926 | 62.929 |
| /run/desktop/mnt/host/c | 1279 | 62.824 | 62.822 | 62.918 | 62.926 | 62.929 |
| /mnt/host/d | 1279 | 78.971 | 78.935 | 79.150 | 79.177 | 79.203 |
| /parent-distro/mnt/host/d | 1279 | 78.971 | 78.935 | 79.150 | 79.177 | 79.203 |
| /run/desktop/mnt/host/d | 1279 | 78.971 | 78.935 | 79.150 | 79.177 | 79.203 |
| /parent-distro/usr/lib/wsl/drivers | 1279 | 62.824 | 62.822 | 62.918 | 62.926 | 62.929 |
| /usr/lib/wsl/drivers | 1279 | 62.824 | 62.822 | 62.918 | 62.926 | 62.929 |
| /parent-distro/init | 1279 | 0.067 | 0.067 | 0.067 | 0.067 | 0.067 |

## Network nhận (B/s)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 1261 | 41.618 | 41.602 | 41.605 | 41.606 | 66.702 |

## Network gửi (B/s)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 1261 | 966.688 | 970.709 | 972.398 | 972.910 | 974.221 |

## Thời gian probe (s)

| service | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| demo-web | 1279 | 0.002 | 0.001 | 0.002 | 0.003 | 0.010 |

## Probe thành công (1=UP)

| service | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| demo-web | 1279 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |

## CPU theo container (%)

| name | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| (không có dữ liệu) | | | | | | |

## RAM theo container (MB)

| name | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| (không có dữ liệu) | | | | | | |
