# Kịch bản demo (khoảng 7 đến 8 phút)

> Các chỗ có dấu `___` điền sau khi chạy kịch bản chính thức; đừng đọc số ước tính. Ngưỡng cảnh báo hiện là bản nháp chờ thống nhất với UTH và mentor VNPT.

## Chuẩn bị trước buổi demo

- [ ] Lab chạy ổn định ít nhất 15 phút (`docker compose ps` đủ 7 container).
- [ ] Luật cảnh báo CPU/RAM/disk đã được bật và nạp (http://localhost:9090/rules không lỗi).
- [ ] Mở sẵn các tab: Grafana (:3000), Prometheus `/alerts` (:9090), Alertmanager (:9093), sơ đồ kiến trúc `docs/architecture.drawio.png`.
- [ ] Mở sẵn một cửa sổ terminal (bash hoặc WSL) tại thư mục gốc repo.
- [ ] Đã chạy thử trọn bộ ít nhất một lần; có ảnh hoặc video quay sẵn mỗi kịch bản làm phương án dự phòng.
- [ ] Dọn dữ liệu thừa: `scenarios/results/events.log` rỗng hoặc đã lưu bản cũ.

## Trình tự

| Thời gian | Nội dung | Làm gì | Gợi ý lời nói |
|---|---|---|---|
| 0:00 đến 0:30 | Mở đầu | Giới thiệu đề tài | "Đề tài N4.7 là prototype giám sát trong lab kiểm soát, không thay thế NOC/DCIM. Nhóm thu metric từ máy chủ, container và dịch vụ, hiển thị trên dashboard, cảnh báo khi vượt ngưỡng và đo thời gian phát hiện qua các kịch bản lỗi." |
| 0:30 đến 1:30 | Kiến trúc | Mở `architecture.drawio.png` | "Prometheus lấy metric mỗi 15 giây từ Node Exporter, cAdvisor và Blackbox. Luật cảnh báo được Prometheus đánh giá rồi đẩy sang Alertmanager để gom nhóm. Grafana đọc từ Prometheus. Toàn bộ dựng bằng Docker Compose." |
| 1:30 đến 2:30 | Baseline và ngưỡng | Mở `docs/baseline_result.md` và bảng ngưỡng trong `architecture.md` | "Nhóm không đặt ngưỡng tùy ý: đã đo baseline 24 giờ lúc lab rảnh. Vì baseline thấp nên ngưỡng là mức vận hành thông thường, kiểm chứng phương pháp bằng dữ liệu NAB, và chờ thống nhất với mentor." |
| 2:30 đến 3:00 | Dashboard lúc bình thường | Mở Grafana | "Đây là trạng thái bình thường: dịch vụ UP, CPU và RAM thấp, chưa có cảnh báo." |
| 3:00 đến 4:00 | Kịch bản 3: service down | `bash scenarios/03_service_down.sh` | Chỉ `ServiceDown` chuyển `pending` rồi `firing` trên Prometheus, rồi hiện trên Alertmanager. "Thời gian phát hiện khoảng ___ giây." |
| 4:00 đến 4:45 | Kịch bản 4: cảnh báo giả | `bash scenarios/01_cpu_high.sh 30` | Chỉ `HighCpuUsage` chỉ ở `pending`, không `firing`. "Đỉnh ngắn hơn thời gian giữ `for:` nên không gây cảnh báo giả." |
| 4:45 đến 5:45 | Kịch bản 1: CPU cao | `bash scenarios/01_cpu_high.sh` | Chỉ `HighCpuUsage` `firing`. "Thời gian phát hiện khoảng ___ giây." Nếu có mức critical, chỉ warning bị ức chế khi critical xuất hiện. |
| 5:45 đến 6:30 | Kịch bản 2: disk đầy giả lập | `bash scenarios/02_disk_full.sh textfile` | Chỉ `DiskSpaceLowSimulated`. "Kịch bản này không đụng tới ổ đĩa thật." |
| 6:30 đến 7:15 | Lịch sử cảnh báo và runbook | Quay lại Grafana, mở `docs/runbook.md` | "Các đợt cảnh báo hiện ở panel lịch sử. Mỗi cảnh báo có hướng xử lý và cách phân biệt cảnh báo giả trong runbook." |
| 7:15 đến 8:00 | Kết quả và hạn chế | Mở `scenarios/results.md` | Đọc bảng thời gian phát hiện (trung bình, nhỏ nhất, lớn nhất) và nêu hạn chế (môi trường, container, kênh thông báo). |

Vì các kịch bản mặc định chạy 120 đến 300 giây, nên bật kịch bản CPU chạy nền trước (mục 3:00) rồi nói tiếp phần khác, hoặc dùng thời lượng ngắn hơn (ví dụ `bash scenarios/01_cpu_high.sh 150`) nhưng phải dài hơn thời gian giữ `for:` của luật.

## Bảng điền thời gian phát hiện (lấy từ `scenarios/results/events.log`)

| Kịch bản | Lần 1 (s) | Lần 2 (s) | Lần 3 (s) | Trung bình (s) |
|---|---|---|---|---|
| Service down | | | | |
| CPU cao | | | | |
| Disk đầy giả lập | | | | |
| Cảnh báo giả (không firing) | | | | không áp dụng |

## Phương án dự phòng

- Kịch bản không `firing` đúng hẹn: mở ảnh hoặc video quay sẵn, nói rõ đây là bản ghi từ lần chạy trước.
- Docker hoặc mạng trục trặc: dùng ảnh Grafana và Prometheus đã chụp trong `scenarios/results/`.
- Panel container trống: nói rõ đây là hạn chế đã biết của Docker Desktop (nhãn `name` của cAdvisor rỗng) và nêu cách nhóm đang xử lý.

## Câu hỏi thường gặp

- **Vì sao chọn ngưỡng này?** Baseline lab thấp nên khoảng dư lớn; ngưỡng là mức vận hành thông thường, kiểm chứng bằng kịch bản và NAB, sẽ chỉnh sau khi thống nhất với mentor.
- **NAB dùng để làm gì?** So sánh các cách đặt ngưỡng và `for:` (số cảnh báo giả, số sự cố bắt được); không dùng số của NAB làm ngưỡng cho lab.
- **Phân biệt cảnh báo giả thế nào?** Thời gian giữ `for:` lọc đỉnh ngắn (kịch bản cảnh báo giả); bảng dấu hiệu và cách xử lý trong `docs/runbook.md`.
- **Thông báo gửi đi đâu?** Hiện xem trên Alertmanager và Grafana; gửi Telegram là phần mở rộng (xem `docs/telegram-notification.md`).
