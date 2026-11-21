# Runbook xử lý cảnh báo (Đề tài N4.7)

Cách dùng: xem tên cảnh báo (`alertname`), máy chủ (`host`/`instance`) và mức độ (`severity`) trên Alertmanager (`http://localhost:9093`) hoặc Grafana (`http://localhost:3000`), sau đó tìm mục tương ứng bên dưới để kiểm tra và xử lý.

## 1. Tổng quan và Nguyên tắc vận hành
- **Mục đích tài liệu:** Hướng dẫn quy trình tra cứu, xác minh và xử lý từng bước khi hệ thống giám sát phát sinh cảnh báo.
- **Phạm vi hạ tầng giám sát với 2 vùng triển khai:**
  - **Vùng 1 – Đối tượng giám sát chính (3 VM Ubuntu 22.04 trên VirtualBox + Vagrant, mạng host-only `192.168.56.0/24`):** 
  - **Vùng 2 – Hệ thống giám sát (Docker Compose trên host / WSL2):**
    - Giao diện theo dõi biểu đồ (Grafana): `http://localhost:3000`
    - Giao diện quản lý cảnh báo (Alertmanager): `http://localhost:9093`
    - Giao diện kiểm tra trạng thái thu thập dữ liệu (Prometheus): `http://localhost:9090`
    - Giao diện tài nguyên container (cAdvisor): `http://localhost:8080`
    - Dịch vụ web mẫu bị giám sát (Demo Web): `http://localhost:8081` 
- **Kênh nhận cảnh báo:** Mặc định theo dõi trực tiếp trên giao diện Alertmanager (`:9093`) và Grafana (`:3000`). Nếu nhóm bật thông báo Telegram (tùy chọn theo `docs/telegram-notification.md`), tin nhắn cảnh báo và tin nhắn đã khắc phục (`resolved`) sẽ gửi về nhóm Telegram test.
- **Nguyên tắc an toàn thông tin:**
  - Mọi thao tác kiểm tra và khôi phục chỉ thực hiện trên môi trường Docker Compose của nhóm.
  - Không sử dụng mật khẩu, token sản xuất và không kết nối tới hạ tầng thật của VNPT.

## 2. Quy trình xử lý cảnh báo tiêu chuẩn
- **Bước 1 – Tiếp nhận và Xác nhận (Acknowledge):**
  - Kiểm tra trạng thái cảnh báo (`pending` hay `firing`), nhãn `alertname`, `host`, `instance`, `severity` trên Alertmanager (`http://localhost:9093`) hoặc panel **Cảnh báo đang firing** trên Grafana.
   - Mở dashboard **HKDN N4.7 - Host & Service Overview**, dùng bộ lọc **Máy chủ**, **Dịch vụ**, **Mountpoint** ở góc trên để quan sát xu hướng metric trước và tại thời điểm phát sinh sự cố.
   - *Lưu ý cơ chế giảm nhiễu (`inhibit`):* Khi một cảnh báo mức `critical` đang `firing`, Alertmanager sẽ tự động ẩn cảnh báo mức `warning` có cùng `alertname` và `instance`.
- **Bước 2 – Khoanh vùng và Phân loại (Triage):**
  - Xác định lỗi nằm ở tầng máy chủ VM (`vm-web`, `vm-db`, `vm-app`), tầng dịch vụ ứng dụng (`nginx`, `hkdn-api`, `hkdn-demo-web`) hay tầng thu thập (`node_exporter`, `prometheus`, `blackbox`).
   - Đối chiếu **Mục Hướng dẫn nhận diện và xử lý Cảnh báo giả (False Positive)** để loại trừ cảnh báo giả (False Positive) hoặc hoạt động chạy kịch bản kiểm thử trước khi can thiệp.
- **Bước 3 – Xử lý và Khôi phục (Mitigate & Recover):**
  - Truy cập đúng VM qua `vagrant ssh <ten-vm>` (chạy trong thư mục `vagrant/`) hoặc thao tác Docker trên máy host theo hướng dẫn từng kịch bản ở Mục "Hướng dẫn xử lý chi tiết theo từng kịch bản sự cố".
- **Bước 4 – Xác nhận hoàn tất và Ghi nhận (Verify & Post-mortem):**
  - Kiểm tra metric trở về ngưỡng bình thường, cảnh báo tự tắt (`resolved`) và ghi thông tin vào biểu mẫu tại Mục "Biểu mẫu ghi nhận nhật ký xử lý sự cố".

## 3. Danh mục cảnh báo và Ngưỡng kích hoạt
*(Cập nhật sau - từ file `config/alert.rules.yml`)*
- **Các trường thông tin sẽ trình bày trong bảng danh mục:**
  - Tên luật cảnh báo (`alertname`) và nhóm luật (`hkdn-availability` / `hkdn-resources`).
  - Mức độ nghiêm trọng (`warning` hoặc `critical`).
  - Đối tượng và chỉ số metric được giám sát.
  - Ngưỡng kích hoạt (sau baseline) và thời gian duy trì điều kiện (`for:`).

- Hệ thống cấu hình **Luật cảnh báo** (cập nhật theo kiến trúc 3 VM Linux): 
*(lay tu baseline-nguong)*

| Nhóm luật | Tên cảnh báo (`alertname`) | Mức độ (`severity`) | Điều kiện / Ngưỡng kích hoạt | Thời gian giữ (`for:`) | Phạm vi áp dụng |
| :--- | :--- | :--- | :--- | :---: | :--- |
| `hkdn-availability` | `NodeExporterDown` | `critical` | `up{job="node",host=~"vm-web\|vm-db\|vm-app"} == 0` | `1m` | Node Exporter trên 3 VM |
| `hkdn-availability` | `ServiceDown` | `critical` | `probe_success{job="blackbox-http"} == 0` | `30s` | HTTP probe (`nginx`, `api`, `demo-web`) |
| `hkdn-resources` | `HighCpuUsage` | `warning` | CPU sử dụng > **70%** *(đề xuất)* | `2m` | `vm-web`, `vm-db`, `vm-app` |
| `hkdn-resources` | `HighCpuUsage` | `critical` | CPU sử dụng > **90%** *(đề xuất)* | `2m` | `vm-web`, `vm-db`, `vm-app` |
| `hkdn-resources` | `HighMemoryUsage` | `warning` | RAM sử dụng > **80%** *(đề xuất)* | `5m` | `vm-web`, `vm-db`, `vm-app` |
| `hkdn-resources` | `HighMemoryUsage` | `critical` | RAM sử dụng > **90%** *(đề xuất)* | `5m` | `vm-web`, `vm-db`, `vm-app` |
| `hkdn-resources` | `DiskSpaceLow` | `warning` | Disk root `/` (`ext4`) > **80%** *(đề xuất)* | `5m` | `vm-web`, `vm-db`, `vm-app` |
| `hkdn-resources` | `DiskSpaceLow` | `critical` | Disk root `/` (`ext4`) > **90%** *(đề xuất)* | `5m` | `vm-web`, `vm-db`, `vm-app` |
| `hkdn-resources` | `DiskSpaceLowSimulated` | `warning` | `hkdn_sim_disk_used_percent > 80` *(đề xuất)* | `1m` | Metric giả lập trên `vm-db` |
> **Lưu ý về ngưỡng và phạm vi:**
> - `NodeExporterDown` chỉ áp dụng cho 3 VM Linux, không áp dụng cho target phụ trợ `lab-host-1` trong Docker.
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
  - Kiểm tra chéo trước khi can thiệp: Đối chiếu giữa Alertmanager (:9093), biểu đồ lịch sử trên Grafana (xem khung 15m–1h) và kiểm tra trực tiếp tình trạng dịch vụ (curl, uptime, df -h) trên VM để xác nhận có ảnh hưởng thực tế không.

  - Tạo Silence có thời hạn trên Alertmanager (khi bảo trì hoặc chạy diễn tập test):

    - Truy cập http://localhost:9093 → chọn mục Silences → bấm New Silence.

    - Chọn khoảng thời gian kết thúc phù hợp (ví dụ 15–30 phút, tuyệt đối không tắt vĩnh viễn).

     - Điền Matchers khớp chính xác cảnh báo cần tạm ẩn (ví dụ alertname="DiskSpaceLowSimulated", host="vm-db").

     - Ghi rõ Creator (tên thành viên) và Comment (lý do, ví dụ "Chạy kịch bản test số 2"), sau đó bấm Create.

   - Đề xuất tinh chỉnh luật cảnh báo: Nếu cảnh báo giả lặp lại do ngưỡng quá nhạy hoặc thời gian for: quá ngắn, ghi nhận vào bảng Incident Log và tạo issue/PR đề xuất chỉnh lại config/alert.rules.yml (kèm minh chứng từ baseline hoặc kết quả thực nghiệm) để nhóm và mentor duyệt.

## 6. Biểu mẫu ghi nhận nhật ký xử lý sự cố (Incident Log)
- **Các cột thông tin cần ghi nhận khi diễn tập và demo:**
  - Số thứ tự và Thời điểm phát hiện cảnh báo.
  - Tên cảnh báo và Phân loại (Sự cố thật / Cảnh báo giả / Chạy kịch bản test).
  - Nguyên nhân gốc xác định được.
  - Câu lệnh / Thao tác đã thực hiện để khôi phục.
  - Thời điểm cảnh báo kết thúc (`resolved`) và Người thực hiện.

## Lưu ý an toàn

Chỉ thao tác trên môi trường lab của nhóm. Không dùng credential sản xuất, không trỏ tới hệ thống/IP thật của VNPT.
