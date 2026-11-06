# Baseline lab N4.7

- Khoảng đo: 2026-11-06 09:14 UTC → 2026-11-06 13:14 UTC (4 giờ), step 15s
- Nguồn: Prometheus http://localhost:9090; biểu thức lấy từ dashboard host-service-overview

## CPU (%)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 961 | 0.270 | 0.254 | 0.296 | 0.395 | 5.736 |

## RAM (%)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 961 | 14.261 | 14.225 | 14.691 | 15.068 | 15.311 |

## Disk (%)

| mountpoint | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| /mnt | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/host/wslg/distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /parent-distro/mnt/host/wslg/distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt/host/wsl/docker-desktop/docker-desktop-user-distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /run/desktop/mnt/host/wslg/distro | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /usr/lib/modules | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /usr/lib/wsl | 961 | 57.978 | 57.978 | 57.978 | 57.978 | 57.978 |
| /mnt/docker-desktop-disk | 961 | 7.577 | 7.577 | 7.579 | 7.579 | 7.579 |
| /parent-distro/mnt/docker-desktop-disk | 961 | 7.577 | 7.577 | 7.579 | 7.579 | 7.579 |
| /run/desktop/mnt/docker-desktop-disk | 961 | 7.577 | 7.577 | 7.579 | 7.579 | 7.579 |
| /var/lib | 961 | 7.577 | 7.577 | 7.579 | 7.579 | 7.579 |
| /mnt/host/c | 961 | 63.121 | 63.127 | 63.159 | 63.217 | 63.337 |
| /parent-distro/mnt/host/c | 961 | 63.121 | 63.127 | 63.159 | 63.217 | 63.337 |
| /run/desktop/mnt/host/c | 961 | 63.121 | 63.127 | 63.159 | 63.217 | 63.337 |
| /mnt/host/d | 961 | 78.796 | 78.871 | 78.979 | 78.979 | 78.979 |
| /parent-distro/mnt/host/d | 961 | 78.796 | 78.871 | 78.979 | 78.979 | 78.979 |
| /run/desktop/mnt/host/d | 961 | 78.796 | 78.871 | 78.979 | 78.979 | 78.979 |
| /parent-distro/usr/lib/wsl/drivers | 961 | 63.121 | 63.127 | 63.159 | 63.217 | 63.337 |
| /usr/lib/wsl/drivers | 961 | 63.121 | 63.127 | 63.159 | 63.217 | 63.337 |
| /parent-distro/init | 961 | 0.067 | 0.067 | 0.067 | 0.067 | 0.067 |

## Network nhận (B/s)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 961 | 41.605 | 41.602 | 41.604 | 41.604 | 42.537 |

## Network gửi (B/s)

| instance | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| node-exporter:9100 | 961 | 1013.759 | 1013.400 | 1016.889 | 1017.356 | 1018.245 |

## Thời gian probe (s)

| service | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| demo-web | 961 | 0.002 | 0.002 | 0.002 | 0.003 | 0.004 |

## Probe thành công (1=UP)

| service | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| demo-web | 961 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |

## CPU theo container (%)

| name | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| (không có dữ liệu) | | | | | | |

## RAM theo container (MB)

| name | Số mẫu | avg | p50 | p95 | p99 | max |
|---|---|---|---|---|---|---|
| (không có dữ liệu) | | | | | | |
