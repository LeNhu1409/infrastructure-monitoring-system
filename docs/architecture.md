## Thành phần

| Thành phần | Vai trò | Cổng |
|---|---|---|
| Prometheus | Thu thập metric, lưu chuỗi thời gian, đánh giá luật cảnh báo | 9090 |
| Node Exporter | Metric của VM Docker Desktop (WSL2): CPU, RAM, disk, network, uptime | 9100 (nội bộ) |
| cAdvisor | Metric theo container | 8080 |
| Blackbox Exporter | Kiểm tra endpoint HTTP (UP/DOWN, thời gian phản hồi) | 9115 (nội bộ) |
| Alertmanager | Gom nhóm, giảm nhiễu, định tuyến cảnh báo | 9093 |
| Grafana | Dashboard theo host/service, xem lịch sử cảnh báo | 3000 |
| demo-web (nginx) | Dịch vụ mẫu bị giám sát | 8081 |

## Luồng dữ liệu

1. Exporter phơi bày metric; Prometheus scrape mỗi 15 giây.
2. Prometheus đánh giá `config/alert.rules.yml`; điều kiện đúng quá thời gian `for:` thì chuyển `pending` -> `firing` và gửi sang Alertmanager.
3. Alertmanager gom nhóm theo `alertname` và `instance` (`group_wait` 10s, `group_interval` 1m, `repeat_interval` 1h). Quy tắc ức chế: khi có cảnh báo `critical`, cảnh báo `warning` cùng `alertname` và `instance` bị bỏ qua. Cảnh báo được gửi tới receiver `default` (chưa gửi ra ngoài, xem trên UI :9093).
4. Grafana truy vấn Prometheus để hiển thị dashboard (`dashboards/host-service-overview.json`) và lịch sử cảnh báo qua metric `ALERTS`.

## Quy ước metric/nhãn

| Job | Nhãn gắn thêm | Ghi chú |
|---|---|---|
| `prometheus` | – | Prometheus tự giám sát chính nó |
| `node` | `host="lab-host-1"` | Metric VM Docker Desktop (WSL2) |
| `cadvisor` | – | Phân biệt container bằng nhãn `name` của cAdvisor |
| `blackbox-http` | `service="demo-web"`, `instance=<URL probe>` | Thêm dịch vụ: thêm URL vào targets, gắn nhãn `service` |

- `severity`: `warning` hoặc `critical`.
- Metric giả lập dùng tiền tố `hkdn_sim_` (xem `scenarios/02_disk_full.sh`).

## Giới hạn đã biết

- Node Exporter chạy trong Docker Desktop nên CPU, RAM, disk là của VM WSL2, không phải máy Windows; metric network là của container (chế độ bridge). Đo host Windows cần thêm windows_exporter (tùy chọn); trên Linux có thể dùng `network_mode: host`.
- Luật cảnh báo theo ngưỡng (CPU, RAM, disk) chưa bật cho đến khi có baseline; ngưỡng sẽ được thống nhất với UTH và mentor VNPT sau khi đo.
- Receiver mặc định chưa gửi ra ngoài (email/chat); cảnh báo chỉ xem trên giao diện Alertmanager và Grafana.
- Dữ liệu Prometheus lưu 15 ngày; lab là prototype một máy, không có HA.
- Chưa kết nối nền tảng quản trị trung tâm dữ liệu thật; chỉ dùng môi trường lab của nhóm, không dùng credential sản xuất.

## Kịch bản lỗi

Ba kịch bản trong `scenarios/` dùng chung `lib.sh`: mỗi kịch bản gây lỗi, thăm dò Prometheus API (`/api/v1/query`, truy vấn `ALERTS`) mỗi 2 giây, ghi sự kiện vào `scenarios/results/events.log` (INJECT, DETECTED/NOT_DETECTED, RECOVER, RESOLVED, DONE), rồi khôi phục.

| Kịch bản | Cách gây lỗi | Cảnh báo kỳ vọng | Ghi chú |
|---|---|---|---|
| `01_cpu_high.sh` (mặc định 300s) | `docker run` container `hkdn-stress-cpu` (alpine) chạy vòng lặp chiếm toàn bộ CPU | `HighCpuUsage` | Chạy ngắn hơn `for:` của luật để chứng minh tăng đột biến ngắn không gây cảnh báo giả |
| `02_disk_full.sh` (mặc định 300s) | Chế độ `textfile`: ghi `hkdn_sim_disk_used_percent=92` vào `scenarios/textfile/sim_disk.prom`; chế độ `loop` (chỉ Linux, cần sudo): ổ ext4 200MB lấp ~92% | `DiskSpaceLowSimulated` (textfile), `DiskSpaceLow` (loop) | Docker Desktop tự chuyển sang `textfile`; không đụng ổ đĩa thật |
| `03_service_down.sh` (mặc định 120s) | `docker stop hkdn-demo-web` | `ServiceDown` | Blackbox probe báo `probe_success=0` |

Thời gian phát hiện (`detection_time`) đo từ lúc gây lỗi xong đến khi cảnh báo `firing` trên Prometheus, độ phân giải ~2s; chưa gồm `group_wait` của Alertmanager.