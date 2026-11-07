# Runbook xử lý cảnh báo (Đề tài N4.7)

Cách dùng: xem tên cảnh báo trên Alertmanager (http://localhost:9093) hoặc Grafana, rồi tìm mục tương ứng bên dưới. Lệnh dưới đây chạy trên máy/VM lab.

## 1. Tổng quan và Nguyên tắc vận hành
- **Mục đích tài liệu:** Hướng dẫn quy trình tra cứu, xác minh và xử lý từng bước khi hệ thống giám sát phát sinh cảnh báo.
- **Các cổng dịch vụ tra cứu trong phòng lab:**
  - Giao diện theo dõi biểu đồ (Grafana): `http://localhost:3000`
  - Giao diện quản lý cảnh báo (Alertmanager): `http://localhost:9093`
  - Giao diện kiểm tra trạng thái thu thập dữ liệu (Prometheus): `http://localhost:9090`
  - Giao diện tài nguyên container (cAdvisor): `http://localhost:8080`
  - Dịch vụ web mẫu bị giám sát (Demo Web): `http://localhost:8081`
- **Nguyên tắc an toàn thông tin:**
  - Mọi thao tác kiểm tra và khôi phục chỉ thực hiện trên môi trường Docker Compose của nhóm.
  - Không sử dụng mật khẩu, token sản xuất và không kết nối tới hạ tầng thật của VNPT.

## 2. Quy trình xử lý cảnh báo tiêu chuẩn
- **Bước 1 – Tiếp nhận và Xác nhận (Acknowledge):**
  - Kiểm tra trạng thái cảnh báo (`pending` hay `firing`) trên Alertmanager và bảng lịch sử cảnh báo của Grafana.
  - Quan sát biểu đồ host/service xung quanh mốc thời gian phát sinh sự cố.
- **Bước 2 – Khoanh vùng và Phân loại (Triage):**
  - Xác định lỗi nằm ở tầng máy chủ (Host), tầng Container hay tầng dịch vụ HTTP (Endpoint).
  - Đối chiếu Mục "Hướng dẫn nhận diện và xử lý Cảnh báo giả" để phân biệt sự cố thật với cảnh báo giả (False Positive).
- **Bước 3 – Xử lý và Khôi phục (Mitigate & Recover):**
  - Thực hiện câu lệnh kiểm tra nguyên nhân và lệnh khắc phục theo từng kịch bản tại Mục "Hướng dẫn xử lý chi tiết theo từng kịch bản sự cố".
- **Bước 4 – Xác nhận hoàn tất và Ghi nhận (Verify & Post-mortem):**
  - Kiểm tra metric trở về ngưỡng bình thường, cảnh báo tự tắt (`resolved`) và ghi thông tin vào biểu mẫu tại Mục "Biểu mẫu ghi nhận nhật ký xử lý sự cố".

## 3. Danh mục cảnh báo và Ngưỡng kích hoạt
*(Cập nhật sau - từ file `config/alert.rules.yml`)*
- **Các trường thông tin sẽ trình bày trong bảng danh mục:**
  - Tên luật cảnh báo (`alertname`) và nhóm luật (`hkdn-availability` / `hkdn-resources`).
  - Mức độ nghiêm trọng (`warning` hoặc `critical`).
  - Đối tượng và chỉ số metric được giám sát.
  - Ngưỡng kích hoạt (sau baseline) và thời gian duy trì điều kiện (`for:`).

## 4. Hướng dẫn xử lý chi tiết theo từng kịch bản sự cố
*(Cập nhật sau - đồng bộ câu lệnh thực nghiệm từ thư mục `scenarios/`)*

### Khung trình bày thống nhất cho mỗi kịch bản cảnh báo:
- **Ý nghĩa và nguyên nhân:** Giải thích hiện tượng kỹ thuật dẫn đến cảnh báo.
- **Dấu hiệu nhận biết:** Trạng thái hiển thị trên Alertmanager và panel tương ứng trên Grafana.
- **Cách kiểm tra xác minh:** Danh sách câu lệnh kiểm tra log, tiến trình và trạng thái container.
- **Thao tác xử lý khôi phục:** Các câu lệnh khắc phục sự cố và khởi động lại dịch vụ.
- **Tiêu chí đóng sự cố:** Dấu hiệu xác nhận hệ thống đã khôi phục hoàn toàn.

### Danh sách các kịch bản sẽ biên soạn chi tiết:
- **Nhóm cảnh báo độ khả dụng (Availability):**
  - Cảnh báo mất kết nối thu thập metric máy chủ (`NodeExporterDown`).
  - Cảnh báo sập dịch vụ / Endpoint HTTP không phản hồi (`ServiceDown` – Kịch bản lỗi số 3).
- **Nhóm cảnh báo tài nguyên hệ thống (Resources):**
  - Cảnh báo quá tải vi xử lý (`HighCpuUsage` – Kịch bản lỗi số 1).
  - Cảnh báo đầy ổ đĩa giả lập (`DiskSpaceLow` / `DiskSpaceLowSimulated` – Kịch bản lỗi số 2).
  - Cảnh báo mức sử dụng bộ nhớ RAM cao (`HighMemoryUsage`).

## 5. Hướng dẫn nhận diện và xử lý Cảnh báo giả (False Positive)
*(Phối hợp nội dung cùng phần Cảnh báo và Kịch bản cảnh báo giả)*
- **Dấu hiệu nhận biết cảnh báo giả:**
  - Tăng tải đột biến ngắn hạn (chỉ lên trạng thái `pending` rồi tự hạ, không chuyển sang `firing`).
  - Cảnh báo xuất hiện đồng loạt do khởi động lại phòng lab hoặc gián đoạn mạng nội bộ Docker.
  - Cảnh báo dao động bật/tắt liên tục do ngưỡng đặt quá sát mức baseline.
  - Cảnh báo phát sinh từ metric mô phỏng (`hkdn_sim_*`) trong quá trình chạy kiểm thử.
- **Hướng xử lý đối với cảnh báo giả:**
  - Quy trình kiểm tra chéo trước khi can thiệp vào container.
  - Cách tạo lệnh tạm ẩn thông báo (`Silence`) có thời hạn trên Alertmanager khi bảo trì/kiểm thử.
  - Quy trình đề xuất điều chỉnh lại ngưỡng hoặc thời gian chờ `for:` trong `config/alert.rules.yml`.

## 6. Biểu mẫu ghi nhận nhật ký xử lý sự cố (Incident Log)
- **Các cột thông tin cần ghi nhận khi diễn tập và demo:**
  - Số thứ tự và Thời điểm phát hiện cảnh báo.
  - Tên cảnh báo và Phân loại (Sự cố thật / Cảnh báo giả / Chạy kịch bản test).
  - Nguyên nhân gốc xác định được.
  - Câu lệnh / Thao tác đã thực hiện để khôi phục.
  - Thời điểm cảnh báo kết thúc (`resolved`) và Người thực hiện.

## Lưu ý an toàn

Chỉ thao tác trên môi trường lab của nhóm. Không dùng credential sản xuất, không trỏ tới hệ thống/IP thật của VNPT.
