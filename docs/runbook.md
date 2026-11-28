# Runbook xử lý cảnh báo (Đề tài N4.7)

Cách dùng: xem tên cảnh báo (`alertname`), máy chủ (`host`/`instance`) và mức độ (`severity`) trên Alertmanager (`http://localhost:9093`) hoặc Grafana (`http://localhost:3000`), sau đó tìm mục tương ứng bên dưới để kiểm tra và xử lý.

## 1. Tổng quan và Nguyên tắc vận hành
- **Mục đích tài liệu:** Hướng dẫn quy trình tra cứu, xác minh và xử lý từng bước khi hệ thống giám sát phát sinh cảnh báo.
- **Phạm vi hạ tầng giám sát với 2 vùng triển khai:**
  - **Vùng 1 – Đối tượng giám sát chính (3 VM Ubuntu 22.04 trên VirtualBox + Vagrant, mạng host-only `192.168.56.0/24`):**
    - `vm-web` (`192.168.56.11`): `nginx` (`:80`), `prometheus-node-exporter` (`:9100`).
    - `vm-db` (`192.168.56.12`): `redis-server` (`:6379`), `mariadb` (`:3306`), `prometheus-node-exporter` (`:9100`), `redis-exporter` (`:9121`), điểm mount giả lập `/mnt/hkdn-small-disk`.
    - `vm-app` (`192.168.56.13`): Python API `hkdn-api` (`:8000/health`), `prometheus-node-exporter` (`:9100`).
  - **Vùng 2 – Hệ thống giám sát (Docker Compose trên host / WSL2):**
    - Grafana (biểu đồ & lịch sử cảnh báo): `http://localhost:3000` (`hkdn-grafana`)
    - Alertmanager (quản lý & tạm ẩn cảnh báo): `http://localhost:9093` (`hkdn-alertmanager`)
    - Prometheus (targets, luật & metric): `http://localhost:9090` (`hkdn-prometheus`)
    - cAdvisor (tài nguyên container – phụ trợ): `http://localhost:8080` (`hkdn-cadvisor`)
    - Demo Web (Nginx mẫu trong Docker – phụ trợ): `http://localhost:8081` (`hkdn-demo-web`)
- **Kênh nhận cảnh báo:** Mặc định theo dõi trực tiếp trên giao diện Alertmanager (`:9093`) và Grafana (`:3000`). Nếu nhóm bật thông báo Telegram (tùy chọn theo `docs/telegram-notification.md`), tin nhắn cảnh báo và tin nhắn đã khắc phục (`resolved`) sẽ gửi về nhóm Telegram test.
- **Nguyên tắc an toàn thông tin:**
  - Mọi thao tác kiểm tra và khôi phục chỉ thực hiện trên 3 VM Vagrant và Docker Compose của nhóm.
  - Không sử dụng mật khẩu, token sản xuất và không kết nối tới hạ tầng thật của VNPT.

## 2. Quy trình xử lý cảnh báo tiêu chuẩn
- **Bước 1 – Tiếp nhận và Xác nhận (Acknowledge):**
  - Kiểm tra trạng thái cảnh báo (`pending` hay `firing`), nhãn `alertname`, `host`, `instance`, `severity` trên Alertmanager (`http://localhost:9093`) hoặc panel **Cảnh báo đang firing** trên Grafana.
   - Mở dashboard **HKDN N4.7 - Host & Service Overview**, dùng bộ lọc **Máy chủ**, **Dịch vụ**, **Mountpoint** ở góc trên để quan sát xu hướng metric trước và tại thời điểm phát sinh sự cố.
   - *Lưu ý cơ chế giảm nhiễu (`inhibit`):* Khi một cảnh báo mức `critical` đang `firing`, Alertmanager sẽ tự động ẩn cảnh báo mức `warning` có cùng `alertname` và `instance`.
- **Bước 2 – Khoanh vùng và Phân loại (Triage):**
  - Xác định lỗi nằm ở tầng máy chủ VM (`vm-web`, `vm-db`, `vm-app`), tầng dịch vụ ứng dụng (`nginx`, `hkdn-api`, `mariadb`, `redis-server`, `hkdn-demo-web`) hay tầng thu thập (`node_exporter`, `prometheus`, `blackbox`).
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
> - Các ngưỡng CPU (70%/90%), RAM (80%/90%) và Disk (80%/90%) là **ngưỡng đề xuất cho prototype** sau đợt đo baseline 18 giờ (CPU nền ~3.5–3.8%, RAM nền ~36–44%, Disk `/` ~5–6%), **chưa phải ngưỡng vận hành thật và đang chờ UTH cùng mentor VNPT duyệt**.
> - `NodeExporterDown` chỉ áp dụng cho 3 VM Linux, không áp dụng cho target phụ trợ `lab-host-1` trong Docker.
> - `ServiceDown` hiện chỉ bao phủ các endpoint HTTP (`blackbox-http`); Redis (`:6379`) và MariaDB (`:3306`) có TCP probe nhưng chưa được luật `ServiceDown` bao phủ.
## 4. Hướng dẫn xử lý chi tiết theo từng kịch bản sự cố
*(Cập nhật sau - đồng bộ câu lệnh thực nghiệm từ `scenarios/`)*

#### Khung trình bày thống nhất cho mỗi kịch bản cảnh báo:
- **Ý nghĩa và nguyên nhân:** Giải thích hiện tượng kỹ thuật dẫn đến cảnh báo.
- **Dấu hiệu nhận biết:** Trạng thái hiển thị trên Alertmanager và panel tương ứng trên Grafana.
- **Cách kiểm tra xác minh:** Danh sách câu lệnh kiểm tra log, tiến trình và trạng thái container.
- **Thao tác xử lý khôi phục:** Các câu lệnh khắc phục sự cố và khởi động lại dịch vụ.
- **Tiêu chí đóng sự cố:** Dấu hiệu xác nhận hệ thống đã khôi phục hoàn toàn.

### 4.0. Lệnh kiểm tra nhanh 3 VM Linux (chạy từ thư mục `vagrant/`)

```bash
# Kiểm tra trạng thái 3 VM
vagrant status

# Kiểm tra trạng thái dịch vụ
vagrant ssh vm-web -c "systemctl status nginx"
vagrant ssh vm-db -c "systemctl status mariadb redis-server"
vagrant ssh vm-app -c "systemctl status hkdn-api"

# Xem log dịch vụ gần nhất
vagrant ssh vm-web -c "journalctl -u nginx -n 50 --no-pager"
vagrant ssh vm-db -c "journalctl -u mariadb -n 50 --no-pager"
vagrant ssh vm-db -c "journalctl -u redis-server -n 50 --no-pager"
vagrant ssh vm-app -c "journalctl -u hkdn-api -n 50 --no-pager"
```

### 4.1. `NodeExporterDown` (`critical`)

- **Ý nghĩa và nguyên nhân:** Prometheus không lấy được metric từ cổng `9100` của một trong 3 VM liên tục quá 1 phút do VM bị tắt, dịch vụ `prometheus-node-exporter` dừng hoặc lỗi kết nối mạng host-only `192.168.56.0/24`.
- **Dấu hiệu nhận biết:** Alertmanager báo `NodeExporterDown`; trang `http://localhost:9090/targets` báo target trong job `node` ở trạng thái **DOWN**; panel **Số target đang UP** trên Grafana giảm và biểu đồ tài nguyên VM bị ngắt dữ liệu.
- **Cách kiểm tra xác minh:**
  ```bash
  # chạy trong thư mục vagrant/
  vagrant status
  vagrant ssh <ten-vm> -c "systemctl status prometheus-node-exporter"
  curl -I http://<ip-vm>:9100/metrics
  ```
- **Thao tác xử lý khôi phục:**
  - Nếu VM đang tắt: `vagrant up <ten-vm>`.
  - Nếu VM đang chạy nhưng Node Exporter dừng:
    ```bash
    vagrant ssh <ten-vm> -c "sudo systemctl restart prometheus-node-exporter"
    ```
- **Tiêu chí đóng sự cố:** Target chuyển **UP** tại `http://localhost:9090/targets`; cảnh báo `NodeExporterDown` chuyển `resolved`.
- **Khả năng cảnh báo giả:** VM vừa khởi động lại hoặc đang bảo trì.

### 4.2. `ServiceDown` (`critical` – Kịch bản lỗi số 3)

- **Ý nghĩa và nguyên nhân:** Blackbox Exporter kiểm tra HTTP (`blackbox-http`) thất bại liên tục quá 30 giây (`probe_success == 0`) đối với Nginx (`vm-web`), Python API (`vm-app`) hoặc `hkdn-demo-web` (Docker).
- **Dấu hiệu nhận biết:** Alertmanager báo `ServiceDown` kèm nhãn `service`; trên Grafana, panel **Trạng thái dịch vụ** chuyển đỏ **DOWN**.
- **Cách kiểm tra xác minh:**
  - Xem `http://localhost:9090/targets` để xác định endpoint bị lỗi.
  - Kiểm tra trạng thái, log và gọi thử endpoint:
    ```bash
    # Với Nginx trên vm-web
    vagrant ssh vm-web -c "systemctl status nginx --no-pager; journalctl -u nginx -n 30 --no-pager"
    curl -i [http://192.168.56.11:80](http://192.168.56.11:80)

    # Với API trên vm-app
    vagrant ssh vm-app -c "systemctl status hkdn-api --no-pager; journalctl -u hkdn-api -n 30 --no-pager"
    curl -i [http://192.168.56.13:8000/health](http://192.168.56.13:8000/health)

    # Với demo-web trong Docker (chạy tại thư mục gốc repo)
    docker ps -a --filter "name=hkdn-demo-web"
    docker logs --tail 30 hkdn-demo-web
    curl -i http://localhost:8081
    ```
- **Thao tác xử lý khôi phục (chỉ chạy sau khi xác định nguyên nhân):**
  ```bash
  vagrant ssh vm-web -c "sudo systemctl restart nginx"
  vagrant ssh vm-app -c "sudo systemctl restart hkdn-api"
  # Hoặc nếu là demo-web trong Docker:
  docker compose up -d demo-web
  ```
- **Tiêu chí đóng sự cố:** Endpoint trả về HTTP `200 OK`; panel **Trạng thái dịch vụ** chuyển xanh **UP**; cảnh báo chuyển `resolved`.
- **Khả năng cảnh báo giả:** Blackbox Exporter hoặc mạng nội bộ gặp lỗi trong khi dịch vụ trên VM vẫn đang hoạt động bình thường.

### 4.3. `HighCpuUsage` (`warning` / `critical` – Kịch bản lỗi số 1)

- **Ý nghĩa và nguyên nhân:** Tỷ lệ dùng CPU trên VM vượt ngưỡng cấu hình (`70%` warning / `90%` critical) liên tục 2 phút. Trong lab thường do kịch bản tạo tải `stress-ng` trên `vm-web` hoặc tiến trình ứng dụng bị kẹt.
- **Dấu hiệu nhận biết:** Alertmanager báo `HighCpuUsage`; biểu đồ **CPU sử dụng (%)** trên Grafana vượt ngưỡng và cao hơn hẳn mức baseline nền (~3.5–3.8%).
- **Cách kiểm tra xác minh:**
  ```bash
  vagrant ssh <ten-vm> -c "uptime; ps aux --sort=-%cpu | head -n 15"
  # Hoặc vào trực tiếp VM để theo dõi theo thời gian thực bằng top
  ```
- **Thao tác xử lý khôi phục:** Xác định tiến trình gây tải và kiểm tra log dịch vụ trước khi can thiệp. Nếu xác nhận do kịch bản kiểm thử `stress-ng`, dừng tiến trình tạo tải (`sudo pkill -f stress-ng`); nếu do dịch vụ lỗi, khởi động lại đúng dịch vụ sau khi lưu log.
- **Tiêu chí đóng sự cố:** Biểu đồ **CPU sử dụng (%)** hạ về mức an toàn dưới ngưỡng; cảnh báo `HighCpuUsage` chuyển `resolved`.
- **Khả năng cảnh báo giả:** Tăng tải ngắn khi khởi động dịch vụ hoặc chạy kịch bản **CPU spike 30 giây** (ngắn hơn `for: 2m`, chỉ lên `pending` rồi tự hạ).

### 4.4. `HighMemoryUsage` (`warning` / `critical`)

- **Ý nghĩa và nguyên nhân:** Tỷ lệ dùng RAM trên VM vượt ngưỡng (`80%` warning / `90%` critical) liên tục 5 phút (mỗi VM có 1 GB RAM; baseline nền ~36% trên `vm-web`/`vm-app` và ~43% trên `vm-db`).
- **Dấu hiệu nhận biết:** Alertmanager báo `HighMemoryUsage`; biểu đồ **RAM sử dụng (%)** duy trì trên ngưỡng trong hơn 5 phút.
- **Cách kiểm tra xác minh:**
  ```bash
  vagrant ssh <ten-vm> -c "free -h; ps aux --sort=-%mem | head -n 15"
  ```
- **Thao tác xử lý khôi phục:** Xác định tiến trình chiếm bộ nhớ, xem log và xu hướng tăng RAM. Chỉ dừng tiến trình bất thường hoặc khởi động lại dịch vụ (`mariadb`, `redis-server`, `hkdn-api`, `nginx`) sau khi xác định nguyên nhân.
- **Tiêu chí đóng sự cố:** Bộ nhớ khả dụng (`available` trong `free -h`) tăng trở lại; biểu đồ **RAM sử dụng (%)** hạ dưới ngưỡng; cảnh báo chuyển `resolved`.
- **Khả năng cảnh báo giả:** Cache hệ điều hành tăng cao. Cần đánh giá theo `MemAvailable`, không chỉ nhìn cột `MemFree`.

### 4.5. `DiskSpaceLow` & `DiskSpaceLowSimulated` (`warning` / `critical` – Kịch bản lỗi số 2)

- **Ý nghĩa và nguyên nhân:**
  - `DiskSpaceLow`: Phân vùng gốc `/` (`ext4`) trên VM vượt `80%` (warning) hoặc `90%` (critical) trong 5 phút.
  - `DiskSpaceLowSimulated`: Metric giả lập `hkdn_sim_disk_used_percent` trên `vm-db` vượt `80%` trong 1 phút (từ ổ loop 200 MB mount tại `/mnt/hkdn-small-disk`, không phản ánh phân vùng gốc `/`).
- **Dấu hiệu nhận biết:** Alertmanager báo `DiskSpaceLow` hoặc `DiskSpaceLowSimulated`; trên Grafana, panel **Disk sử dụng (%)** (chọn bộ lọc **Mountpoint**) tăng vọt vượt 80%.
- **Cách kiểm tra xác minh:**
  ```bash
  # Kiểm tra disk thật trên VM tương ứng
  vagrant ssh <ten-vm> -c "df -h /; sudo du -xhd1 /var /home 2>/dev/null | sort -h"

  # Kiểm tra disk giả lập trên vm-db
  vagrant ssh vm-db -c "mountpoint /mnt/hkdn-small-disk; df -h /mnt/hkdn-small-disk"
  ```
- **Thao tác xử lý khôi phục:**
  - **Với `DiskSpaceLow` (ổ thật):** Xác định thư mục/log phình to và nguyên nhân tăng dung lượng rồi mới dọn dẹp (ví dụ dọn log systemd an toàn); không xóa dữ liệu tùy tiện.
  - **Với `DiskSpaceLowSimulated` (ổ giả lập):** Kiểm tra và dọn filesystem loop cùng metric mô phỏng theo hướng dẫn trong `scenarios/vm/02_disk_full_vm.sh`.
- **Tiêu chí đóng sự cố:** Tỷ lệ dùng `/` hoặc giá trị `hkdn_sim_disk_used_percent` giảm dưới 80%; cảnh báo chuyển `resolved`.
- **Khả năng cảnh báo giả:** Metric giả lập `hkdn_sim_*` còn sót lại sau khi chạy kịch bản test, hoặc filesystem ảo (`squashfs`, `tmpfs`, `loop`) bị tính nhầm.


---
## 5. Hướng dẫn nhận diện và xử lý Cảnh báo giả (False Positive)
*(Phối hợp nội dung cùng phần Cảnh báo và Kịch bản cảnh báo giả)*

### 5.1. Bảng nhận diện nhanh

| Dấu hiệu | Khả năng | Việc cần làm |
| :--- | :--- | :--- |
| Chỉ lên `pending`, tự hết trước khi đủ `for:` (ví dụ CPU spike 30 giây) | Tăng tải ngắn hạn, đúng cơ chế giữ cảnh báo | Theo dõi thêm; chỉ cân nhắc chỉnh `for:` nếu lặp lại thường xuyên |
| Nhiều cảnh báo bật đồng loạt cùng lúc | Sự cố chung (mạng host-only, Prometheus, host) hoặc vừa khởi động lại lab | Kiểm tra `up` và `http://localhost:9090/targets` trước khi xử lý từng dịch vụ |
| Metric có tiền tố `hkdn_sim_` | Do chạy kịch bản disk giả lập | Đối chiếu `scenarios/results/events.log` và dọn theo kịch bản |
| Cảnh báo lặp, dao động bật/tắt quanh ngưỡng | Ngưỡng đặt quá sát mức baseline thường ngày | Đo lại baseline, đề xuất chỉnh ngưỡng hoặc `for:` |
| RAM cao nhưng `MemAvailable` vẫn ổn | Do cache hệ điều hành | Đánh giá theo `MemAvailable` thay vì `MemFree` |
| Cảnh báo phát sinh đúng giờ bảo trì / diễn tập | Hoạt động có kế hoạch | Tạo `Silence` có thời hạn trên Alertmanager |

### 5.2. Quy trình xử lý cảnh báo giả

1. **Kiểm tra chéo trước khi can thiệp:** Đối chiếu Alertmanager (`http://localhost:9093`), biểu đồ Grafana (khung 15m–1h) và kiểm tra trực tiếp trên VM (`curl`, `uptime`, `free -h`, `df -h`) để chắc chắn không có ảnh hưởng thật.
2. **Tạo Silence có thời hạn trên Alertmanager (khi bảo trì hoặc chạy kịch bản test):**
   - Mở `http://localhost:9093` → chọn **Silences** → bấm **New Silence**.
   - Đặt thời hạn kết thúc ngắn (ví dụ 15–30 phút, không tắt vĩnh viễn).
   - Điền **Matchers** khớp cảnh báo cần tạm ẩn (ví dụ `alertname="DiskSpaceLowSimulated"`, `host="vm-db"`).
   - Ghi rõ **Creator** (tên thành viên) và **Comment** (lý do, ví dụ `"Chạy kịch bản test số 2"`), sau đó bấm **Create**.
3. **Đề xuất tinh chỉnh luật cảnh báo:** Ghi nhận vào bảng Incident Log (Mục 6) và mở issue/PR đề xuất chỉnh ngưỡng hoặc `for:` trong `config/alert.rules.yml` kèm dữ liệu baseline/kiểm thử để nhóm và mentor duyệt.


## 6. Biểu mẫu ghi nhận nhật ký xử lý sự cố (Incident Log)
Ghi nhận đầy đủ cho các lần diễn tập kịch bản lỗi, kiểm thử cảnh báo giả hoặc sự cố phát sinh (đồng bộ mốc thời gian với `scenarios/results/events.log`):

| STT | Mốc phát hiện (`DETECTED`) | Tên cảnh báo (`alertname`) | Đối tượng (`host` / `service`) | Phân loại | Nguyên nhân gốc | Thao tác / Câu lệnh đã xử lý | Mốc kết thúc (`RESOLVED`) | Người thực hiện |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 0 *(Mẫu)* | `2026-11-28 09:15:30` | `ServiceDown` | `vm-web` / `nginx` | Chạy kịch bản test | Dừng Nginx chủ động khi chạy `03_service_down_vm.sh` | `vagrant ssh vm-web -c "sudo systemctl restart nginx"` | `2026-11-20 09:16:05` | Thành viên A |
| 1 | | | | | | | | |

## Lưu ý an toàn

**Chỉ thao tác trên môi trường lab của nhóm. Không dùng credential sản xuất, không trỏ tới hệ thống/IP thật của VNPT.**
