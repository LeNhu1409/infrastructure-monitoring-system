# Kịch bản demo (khoảng 7 đến 8 phút)

> Các chỗ có dấu `___` điền sau khi chạy kịch bản chính thức; không đọc số ước tính. Ngưỡng cảnh báo hiện là bản nháp chờ thống nhất với UTH và mentor VNPT.

## Chuẩn bị trước buổi demo

- [ ] Lab chạy ổn định ít nhất 15 phút.
- [ ] Docker Compose có đủ 7 container cần thiết: Prometheus, Alertmanager, Grafana, Node Exporter, cAdvisor, Blackbox Exporter và demo-web.
- [ ] Ba VM `vm-web`, `vm-db`, `vm-app` đều ở trạng thái `running` (`vagrant status`).
- [ ] Luật cảnh báo CPU/RAM/disk đã được bật và nạp tại http://localhost:9090/rules.
- [ ] Mở sẵn Grafana (:3000), Prometheus `/alerts` (:9090), Alertmanager (:9093) và sơ đồ `docs/architecture.drawio.png`.
- [ ] Mở terminal tại thư mục gốc repo.
- [ ] Đã chạy thử trọn bộ ít nhất một lần; có ảnh hoặc video quay sẵn mỗi kịch bản làm phương án dự phòng.
- [ ] Dọn dữ liệu thừa: `scenarios/results/events.log` rỗng hoặc đã lưu bản cũ.

## Trình tự

| Thời gian | Nội dung | Làm gì | Gợi ý lời nói |
|---|---|---|---|
| 0:00 đến 0:30 | Mở đầu | Giới thiệu đề tài | "Đề tài N4.7 là prototype giám sát trong lab kiểm soát, không thay thế NOC/DCIM. Nhóm thu metric từ máy chủ, container và dịch vụ, hiển thị trên dashboard, cảnh báo khi vượt ngưỡng và đo thời gian phát hiện qua các kịch bản lỗi." |
| 0:30 đến 1:30 | Kiến trúc | Mở `architecture.drawio.png` | "Lab có ba máy ảo Linux: vm-web, vm-db và vm-app, chạy các dịch vụ khác nhau. Prometheus thu metric từ Node Exporter, cAdvisor và Blackbox Exporter. Luật cảnh báo được đánh giá rồi chuyển sang Alertmanager; Grafana đọc dữ liệu từ Prometheus. Các thành phần giám sát được triển khai bằng Docker Compose." |
| 1:30 đến 2:30 | Baseline và ngưỡng | Mở `docs/baseline_result.md` và bảng ngưỡng trong `docs/architecture.md` | "Nhóm đã đo baseline trong khoảng 18 giờ của lần thu thập gần nhất, chưa đủ 24 giờ. Nhóm sử dụng số liệu thực tế để tham khảo trạng thái bình thường, đề xuất ngưỡng vận hành và kiểm chứng bằng các kịch bản thử nghiệm cùng dữ liệu NAB. Ngưỡng hiện vẫn là bản đề xuất chờ thống nhất với mentor." |
| 2:30 đến 3:00 | Dashboard lúc bình thường | Mở Grafana | "Đây là trạng thái bình thường: các dịch vụ đang hoạt động, CPU và RAM ở mức thấp, chưa có cảnh báo." |
| 3:00 đến 4:00 | Kịch bản 3: Service down | `bash scenarios/vm/03_service_down_vm.sh` | Chỉ `ServiceDown` chuyển `pending` rồi `firing` trên Prometheus, sau đó xuất hiện trên Alertmanager. "Thời gian phát hiện khoảng ___ giây." |
| 4:00 đến 4:45 | Kịch bản 4: CPU spike ngắn | `bash scenarios/vm/01_cpu_high_vm.sh 30` | Chỉ `HighCpuUsage` ở `pending`, không chuyển `firing`. "Đỉnh CPU ngắn hơn thời gian giữ `for:` nên không phát sinh cảnh báo firing." |
| 4:45 đến 5:45 | Kịch bản 1: CPU cao | `bash scenarios/vm/01_cpu_high_vm.sh` | Chỉ `HighCpuUsage` chuyển `firing`. "Thời gian phát hiện khoảng ___ giây." Nếu có mức critical, giải thích cơ chế inhibit khi critical xuất hiện. |
| 5:45 đến 6:30 | Kịch bản 2: Disk đầy giả lập | `bash scenarios/vm/02_disk_full_vm.sh` | Chỉ `DiskSpaceLowSimulated`. "Kịch bản này tạo ổ đĩa loop giả lập trên vm-db, không làm đầy ổ đĩa thật." |
| 6:30 đến 7:15 | Lịch sử cảnh báo và runbook | Quay lại Grafana, mở `docs/runbook.md` | "Các đợt cảnh báo được thể hiện trên dashboard. Mỗi cảnh báo có hướng kiểm tra và xử lý tương ứng trong runbook." |
| 7:15 đến 8:00 | Kết quả và hạn chế | Mở `scenarios/results.md` | Đọc bảng thời gian phát hiện thực tế và nêu hạn chế về môi trường lab, container và kênh thông báo. |

> Các kịch bản mặc định có thời lượng tương đối dài. Có thể dùng `bash scenarios/vm/01_cpu_high_vm.sh 150` để rút ngắn demo CPU cao, nhưng thời lượng phải đủ dài để luật cảnh báo chuyển sang `firing`. Kịch bản CPU spike ngắn dùng riêng thời lượng 30 giây.

## Bảng điền thời gian phát hiện

Lấy số liệu từ `scenarios/results/events.log` sau khi chạy kịch bản chính thức.

| Kịch bản | Lần 1 (s) | Lần 2 (s) | Lần 3 (s) | Trung bình (s) |
|---|---:|---:|---:|---:|
| Service down | | | | |
| CPU cao | | | | |
| Disk đầy giả lập | | | | |
| CPU spike ngắn | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng |

## Phương án dự phòng

- Kịch bản không `firing` đúng hẹn: mở ảnh hoặc video quay sẵn, nói rõ đây là bản ghi từ lần chạy trước.
- Docker hoặc mạng trục trặc: dùng ảnh Grafana và Prometheus đã chụp trong `scenarios/results/`.
- Panel container trống: nêu rõ đây là hạn chế đã biết của môi trường Docker Desktop/cAdvisor.
- VM không hoạt động: kiểm tra `vagrant status` và trạng thái dịch vụ bằng `systemctl`.

## Câu hỏi thường gặp

- **Vì sao chọn ngưỡng này?** Baseline lab phản ánh môi trường thử nghiệm, không đại diện tải production. Ngưỡng hiện là mức đề xuất vận hành, được kiểm chứng bằng kịch bản và NAB, chờ thống nhất với mentor.
- **NAB dùng để làm gì?** So sánh các cách đặt ngưỡng và thời gian giữ `for:` thông qua số cảnh báo giả và số sự cố phát hiện được; không lấy trực tiếp số liệu NAB làm ngưỡng cho lab.
- **CPU spike ngắn có ý nghĩa gì?** Kiểm tra khả năng lọc đỉnh CPU ngắn bằng thời gian giữ `for:`, tránh phát sinh cảnh báo `firing` không cần thiết.
- **Thông báo gửi đi đâu?** Hiện xem trên Alertmanager và Grafana; gửi Telegram là phần mở rộng (xem `docs/telegram-notification.md`).