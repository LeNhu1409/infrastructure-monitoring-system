# Runbook xử lý cảnh báo

Cách dùng: xem tên cảnh báo trên Alertmanager (http://localhost:9093) hoặc Grafana, rồi tìm mục tương ứng bên dưới. Lệnh dưới đây chạy trên máy/VM lab.

## Quy trình chung

1. **Xác nhận**: cảnh báo còn `firing` không? Mở dashboard "HKDN N4.7 - Host & Service Overview" xem biểu đồ quanh thời điểm cảnh báo.
2. **Khoanh vùng**: lỗi ở host, container hay dịch vụ?
3. **Xử lý** theo mục tương ứng.
4. **Ghi nhận**: giờ phát hiện, nguyên nhân, cách xử lý, giờ hết cảnh báo (ghi vào biên bản/nhật ký của nhóm).

## NodeExporterDown (critical)

- **Ý nghĩa**: Prometheus không lấy được metric của host trong hơn 1 phút.
- **Kiểm tra**: `docker compose ps`, `docker logs hkdn-node-exporter --tail 50`, vào http://localhost:9090/targets xem lỗi.
- **Xử lý**: `docker compose restart node-exporter`. Nếu cả host chết thì kiểm tra VM/máy lab.
- **Có thể là cảnh báo giả khi**: vừa khởi động lại lab hoặc đang bảo trì.

> Các cảnh báo CPU, RAM, disk bên dưới chỉ hoạt động sau khi nhóm bật luật tương ứng trong `config/alert.rules.yml`.

## HighCpuUsage (warning)

- **Ý nghĩa**: CPU trung bình vượt ngưỡng liên tục trong một khoảng thời gian (ngưỡng chưa chốt, chờ baseline).
- **Kiểm tra**: `docker stats --no-stream` hoặc panel "CPU theo container" để thấy container nào ngốn CPU; `top` trên host.
- **Xử lý**: dừng/giới hạn container gây tải (`docker update --cpus 1 <tên>`), tìm nguyên nhân gốc (vòng lặp, tải tăng đột biến).
- **Có thể là cảnh báo giả khi**: tăng ngắn do build/khởi động; tăng `for:` hoặc dùng trung bình dài hơn nếu lặp lại nhiều.

## HighMemoryUsage (warning)

- **Ý nghĩa**: RAM dùng vượt ngưỡng trong một khoảng thời gian (ngưỡng chưa chốt, chờ baseline).
- **Kiểm tra**: `free -h`, panel "RAM theo container", `docker stats --no-stream`.
- **Xử lý**: khởi động lại hoặc đặt giới hạn bộ nhớ cho container ngốn RAM (`mem_limit`), kiểm tra rò rỉ bộ nhớ.
- **Có thể là cảnh báo giả khi**: cache hệ điều hành lớn; dùng `MemAvailable` (đã dùng) thay vì `MemFree`.

## DiskSpaceLow / DiskSpaceLowSimulated (warning)

- **Ý nghĩa**: phân vùng đã dùng vượt ngưỡng (ngưỡng chưa chốt, chờ baseline). `Simulated` là bản dùng cho kịch bản giả lập.
- **Kiểm tra**: `df -h`, `du -xh --max-depth=1 <mountpoint> | sort -h | tail`, `docker system df`.
- **Xử lý**: dọn file lớn/log cũ, `docker system prune` (cẩn thận, hỏi nhóm trước), mở rộng ổ nếu cần.
- **Có thể là cảnh báo giả khi**: là metric `hkdn_sim_*` (giả lập) hoặc phân vùng chỉ đọc luôn đầy (squashfs, loop của snap); thêm vào bộ lọc `fstype`.

## ServiceDown (critical)

- **Ý nghĩa**: kiểm tra HTTP tới dịch vụ thất bại hơn 30 giây.
- **Kiểm tra**: `docker ps -a | grep demo-web`, `docker logs hkdn-demo-web --tail 50`, `curl -i http://localhost:8081`, http://localhost:9090/targets (job `blackbox-http`).
- **Xử lý**: `docker start hkdn-demo-web` (hoặc `docker compose up -d demo-web`), xem log tìm nguyên nhân.
- **Có thể là cảnh báo giả khi**: Blackbox Exporter lỗi mạng nội bộ chứ dịch vụ vẫn sống. Kiểm tra bằng `curl` trực tiếp và xem `probe_success` có đồng loạt về 0 cho mọi dịch vụ không.

## Cách phân biệt cảnh báo giả

| Dấu hiệu | Khả năng | Việc làm |
|---|---|---|
| Chỉ `pending`, tự hết trong vài chục giây | Tăng ngắn, đúng cơ chế `for:` | Không cần xử lý; cân nhắc tăng `for:` nếu lặp lại |
| Nhiều cảnh báo cùng lúc, cùng giờ | Sự cố chung (mạng, Prometheus, host) hoặc vừa khởi động lại | Kiểm tra `up` và http://localhost:9090/targets trước |
| Metric có tiền tố `hkdn_sim_` | Do kịch bản giả lập | Đối chiếu `scenarios/results/events.log` |
| Cảnh báo lặp, dao động quanh ngưỡng | Ngưỡng sát giá trị thường ngày | Đo baseline, chỉnh ngưỡng hoặc `for:` |
| Cảnh báo đúng giờ bảo trì | Bảo trì có kế hoạch | Tạm tắt (silence) trên Alertmanager, có thời hạn |

## Lưu ý an toàn

Chỉ thao tác trên môi trường lab của nhóm. Không dùng credential sản xuất, không trỏ tới hệ thống/IP thật của VNPT.
