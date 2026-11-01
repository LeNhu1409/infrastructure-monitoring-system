## Thành phần

| Thành phần | Vai trò | Cổng |
|---|---|---|
| Prometheus | Thu thập metric, lưu chuỗi thời gian, đánh giá luật cảnh báo | 9090 |
| Node Exporter | Metric máy chủ: CPU, RAM, disk, network, uptime | 9100 (nội bộ) |
| cAdvisor | Metric theo container | 8080 |
| Blackbox Exporter | Kiểm tra endpoint HTTP (UP/DOWN, thời gian phản hồi) | 9115 (nội bộ) |
| Alertmanager | Gom nhóm, giảm nhiễu, định tuyến cảnh báo | 9093 |
| Grafana | Dashboard theo host/service, xem lịch sử cảnh báo | 3000 |
| demo-web (nginx) | Dịch vụ mẫu bị giám sát | 8081 |

## Luồng dữ liệu

1. Exporter phơi bày metric; Prometheus scrape mỗi 15 giây.
2. Prometheus đánh giá `config/alert.rules.yml`; điều kiện đúng quá thời gian `for:` thì chuyển `pending` -> `firing` và gửi sang Alertmanager.
3. Alertmanager gom nhóm, áp quy tắc ức chế (critical che warning cùng loại) rồi gửi tới receiver.
4. Grafana truy vấn Prometheus để hiển thị dashboard (`dashboards/host-service-overview.json`) và lịch sử cảnh báo qua metric `ALERTS`.

## Quy ước metric/nhãn

- `job`: `node`, `cadvisor`, `blackbox-http`, `prometheus`.
- `host`: tên máy lab (ví dụ `lab-host-1`); `service`: tên dịch vụ được probe.
- `severity`: `warning` hoặc `critical`.
- Metric giả lập dùng tiền tố `hkdn_sim_`.

## Giới hạn đã biết

- Metric network của Node Exporter là của container (chế độ bridge); đo card mạng thật của host cần `network_mode: host` trên Linux.
- Luật cảnh báo theo ngưỡng (CPU, RAM, disk) chưa bật vì chưa có baseline; chờ đo và thống nhất với UTH, mentor VNPT.
- Chưa kết nối nền tảng quản trị trung tâm dữ liệu thật; chỉ dùng môi trường lab của nhóm.
