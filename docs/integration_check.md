# Kiểm tra tích hợp end-to-end

Mục đích: chứng minh toàn hệ thống chạy từ đầu đến cuối, từ dựng lab trên máy sạch, thu metric, hiển thị, gây lỗi, cảnh báo, đến hồi phục. Làm sau khi luật cảnh báo CPU/RAM/disk đã được bật trong `config/alert.rules.yml`.

Cách dùng: chạy lần lượt các bước, điền cột **Kết quả** (Đạt / Không đạt) và **Ghi chú**, đính kèm ảnh vào `scenarios/results/`. Cột Kết quả để trống nghĩa là chưa chạy.

## Thông tin lần chạy

| Mục | Giá trị |
|---|---|
| Ngày giờ | |
| Người thực hiện | |
| Commit của repo (`git rev-parse --short HEAD`) | |
| Máy / HĐH / RAM / số core | |
| Phiên bản Docker và Compose (`docker --version`, `docker compose version`) | |

## A. Chuẩn bị (máy sạch)

```bash
git clone https://github.com/LeNhu1409/infrastructure-monitoring-system
cd infrastructure-monitoring-system
git checkout <nhánh cần kiểm tra>
cp .env.example .env        # đổi mật khẩu Grafana trong .env
docker compose up -d
```

Chờ khoảng 1 đến 2 phút cho các exporter có số liệu. Script trong `scenarios/` chạy bằng `bash` (Windows dùng WSL).

## B. Danh sách kiểm tra

| Mã | Kiểm tra | Cách làm | Kỳ vọng | Kết quả | Ghi chú |
|---|---|---|---|---|---|
| B1 | Các container đang chạy | `docker compose ps` | 7 container `Up`: prometheus, alertmanager, grafana, node-exporter, cadvisor, blackbox, demo-web | | |
| B2 | Các target được thu thập | Mở http://localhost:9090/targets | 4 job `prometheus`, `node`, `cadvisor`, `blackbox-http` đều `UP` | | |
| B3 | Metric máy chủ có dữ liệu | Truy vấn `up{job="node"}` và `node_boot_time_seconds` trên http://localhost:9090/graph | Giá trị `1` và có số | | |
| B4 | Dashboard hiển thị | Mở http://localhost:3000, dashboard "HKDN N4.7 - Host & Service Overview" | Bốn ô trạng thái có số; panel CPU, RAM, Disk, Network có đường; panel container có dữ liệu | | Ghi rõ panel nào trống |
| B5 | Luật cảnh báo được nạp | Mở http://localhost:9090/rules | Thấy nhóm `hkdn-availability` và `hkdn-resources` (khi đã bật), không có lỗi | | |
| B6 | Prometheus nối được Alertmanager | `curl -s http://localhost:9090/api/v1/alertmanagers` và mở http://localhost:9093 | `activeAlertmanagers` có 1 mục; giao diện Alertmanager mở được | | |
| B7 | Kịch bản 3: service down | `bash scenarios/03_service_down.sh` | `events.log` có INJECT, DETECTED (`ServiceDown`), RECOVER, RESOLVED, DONE | | Thời gian phát hiện: ___ giây |
| B8 | Kịch bản 1: CPU cao | `bash scenarios/01_cpu_high.sh` | `HighCpuUsage` lên `firing`, sau đó tự hết | | Thời gian phát hiện: ___ giây |
| B9 | Kịch bản 2: disk đầy giả lập | `bash scenarios/02_disk_full.sh textfile` | `DiskSpaceLowSimulated` lên `firing`, sau đó tự hết | | Thời gian phát hiện: ___ giây |
| B10 | Kịch bản 4: cảnh báo giả | `bash scenarios/01_cpu_high.sh 30` | `HighCpuUsage` chỉ ở `pending`, không `firing` | | |
| B11 | Alertmanager nhận cảnh báo | Mở http://localhost:9093 trong lúc chạy B7 đến B9 | Cảnh báo xuất hiện, gom nhóm theo `alertname` và `instance` | | |
| B12 | Lịch sử cảnh báo trên dashboard | Xem panel "Lịch sử cảnh báo (firing)" sau B7 đến B9 | Thấy các đợt cảnh báo đúng thời điểm | | |
| B13 | Dọn dẹp sau kịch bản | `docker ps -a`, kiểm tra `scenarios/textfile/` | Không còn container `hkdn-stress-cpu`; `hkdn-demo-web` đang chạy; không còn `sim_disk.prom` | | |
| B14 | Không có bí mật trong repo | `git grep -niE "password\|token\|secret" -- . ':!docs' ':!README.md'` | Không có mật khẩu hay token thật (chỉ có tên biến hoặc chú thích) | | |
| B15 | Dựng lại từ đầu | `docker compose down -v` rồi `docker compose up -d`, lặp lại B1 đến B4 | Các bước vẫn đạt | | |

Gợi ý lệnh xem log kịch bản: `cat scenarios/results/events.log`.

## C. Lỗi và bất thường ghi nhận

| Mã | Mô tả | Mức độ | Cách xử lý hoặc kế hoạch |
|---|---|---|---|
| | | | |

## D. Kết luận

- Số mục đạt: ___ / 15
- Các mục chưa đạt và lý do: 
- Người xác nhận: 
