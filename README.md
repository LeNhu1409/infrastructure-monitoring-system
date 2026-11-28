# HKDN UTH – VNPT NET | Đề tài N4.7

**Xây dựng hệ thống giám sát máy chủ, Cloud và trung tâm dữ liệu**

Nhóm 11 – Học kỳ doanh nghiệp UTH – VNPT NET (01/11/2026 – 06/03/2027)

Prototype quan sát (observability) trong môi trường lab kiểm soát: thu thập metric, dashboard, cảnh báo ngưỡng và mô phỏng lỗi. Đây là mô hình nhiều máy chủ phục vụ thử nghiệm giám sát, không phải mô phỏng đầy đủ nền tảng Cloud hay thay thế NOC/DCIM trung tâm dữ liệu thực tế.

## Công nghệ

`Prometheus`, `Grafana`, `Alertmanager`, `Node Exporter`, `Redis Exporter`, `cAdvisor`, `Blackbox Exporter`, `Docker Compose`, `VirtualBox`, `Vagrant`.

## Môi trường lab
Hệ thống gồm 2 vùng triển khai
1. **Đối tượng giám sát chính (VirtualBox + Vagrant):** 3 VM Ubuntu 22.04 trên mạng host-only `192.168.56.0/24`:
   - `vm-web` (`192.168.56.11`): Nginx (`:80`), Node Exporter (`:9100`).
   - `vm-db` (`192.168.56.12`): Redis (`:6379`), MariaDB (`:3306`), Node Exporter (`:9100`), Redis Exporter (`:9121`).
   - `vm-app` (`192.168.56.13`): Python API (`:8000/health`, service `hkdn-api`), Node Exporter (`:9100`).
2. **Monitoring stack (Docker Compose):** Chạy Prometheus, Grafana, Alertmanager, Blackbox Exporter cùng các target phụ trợ (`node-exporter` `lab-host-1`, `cAdvisor`, `demo-web`).

## Cổng dịch vụ và Phụ thuộc khởi chạy

### Danh sách cổng sử dụng

| Vùng triển khai | Thành phần / Host | Cổng | Phạm vi truy cập | Vai trò |
| :--- | :--- | :---: | :--- | :--- |
| Docker Compose | `hkdn-grafana` | `3000` | Host (`localhost:3000`) | Giao diện Dashboard & lịch sử cảnh báo |
| Docker Compose | `hkdn-cadvisor` | `8080` | Host (`localhost:8080`) | Metric tài nguyên container (phụ trợ) |
| Docker Compose | `hkdn-demo-web` | `8081` → `80` | Host (`localhost:8081`) | Dịch vụ Nginx mẫu trong Docker (phụ trợ) |
| Docker Compose | `hkdn-prometheus` | `9090` | Host (`localhost:9090`) | Thu thập metric, truy vấn PromQL, đánh giá luật |
| Docker Compose | `hkdn-alertmanager` | `9093` | Host (`localhost:9093`) | Gom nhóm, ức chế (`inhibit`), tạm ẩn cảnh báo |
| Docker Compose | `hkdn-node-exporter` | `9100` | Nội bộ Docker | Metric Docker Desktop (`lab-host-1`, phụ trợ) |
| Docker Compose | `hkdn-blackbox` | `9115` | Nội bộ Docker | Probe HTTP (`http_2xx`) và TCP (`tcp_connect`) |
| 3 VM Vagrant | `vm-web` (`192.168.56.11`) | `80`, `9100` | Mạng `192.168.56.0/24` | Nginx & Node Exporter |
| 3 VM Vagrant | `vm-db` (`192.168.56.12`) | `6379`, `3306`, `9100`, `9121` | Mạng `192.168.56.0/24` | Redis, MariaDB, Node Exporter & Redis Exporter |
| 3 VM Vagrant | `vm-app` (`192.168.56.13`) | `8000`, `9100` | Mạng `192.168.56.0/24` | Python API (`hkdn-api`) & Node Exporter |

### Thứ tự phụ thuộc khi triển khai

1. **Tầng hạ tầng VM chạy trước:** 3 VM Ubuntu (`vm-web`, `vm-db`, `vm-app`) cần được khởi chạy qua Vagrant trước để mở mạng host-only `192.168.56.0/24` và phơi bày các cổng exporter/dịch vụ.
2. **Tầng Monitoring Stack (Docker Compose) chạy sau:**
   - Yêu cầu file `.env` (tạo từ `.env.example`) chứa biến `GRAFANA_ADMIN_PASSWORD`.
   - Phụ thuộc giữa các container: `prometheus` phụ thuộc `alertmanager`; `grafana` phụ thuộc `prometheus` (tự động nạp datasource và dashboard từ `grafana/provisioning/` và `dashboards/`).
 


## Dựng lab trên máy sạch

### 1. Yêu cầu môi trường
- Máy tính cá nhân có RAM từ **8–16 GB** (khuyến nghị 16 GB khi chạy đồng thời 3 VM và Docker Desktop).
- Đã cài đặt **Docker** và **Docker Compose**.
- Đã cài đặt **VirtualBox** và **Vagrant** (để dựng cụm 3 VM Linux; xem chi tiết tại `docs/vm-environment.md`).
- Đã cài đặt `git` và `curl` (cần thêm `python3` nếu chạy các công cụ trong `tools/`).
- **Lưu ý cho Windows:** Bật WSL2 backend trong Docker Desktop và dùng WSL (Ubuntu) hoặc Git Bash để chạy các script `.sh` trong thư mục `scenarios/`.

### 2. Các bước khởi chạy từ đầu
**Bước 1 – Clone repo và tạo file biến môi trường**
```bash
git clone <link-repo>
cd infrastructure-monitoring-system
cp .env.example .env     # đổi mật khẩu Grafana trong .env tại GRAFANA_ADMIN_PASSWORD
docker compose up -d
docker compose ps
```

**Bước 2 – Dựng cụm 3 VM Linux**
```bash 
cd vagrant
vagrant up
vagrant status  # kiểm tra cả 3 VM (vm-web, vm-db, vm-app) đều ở trạng thái running
cd ..
```

**Bước 3 - Khởi chạy Monitoring stack bằng Docker Compose**
```bash
docker-compose up -d
docker-compose ps
```
### 3. Kiểm tra trạng thái khi dựng lab
| Dịch vụ | Địa chỉ | Cách kiểm tra hoạt động |
|---|---|---|
| Prometheus | http://localhost:9090 | Vào mục `Status` -> `Targets`, kiểm tra đủ 6 job (`prometheus`, `node` gồm `lab-host-1` và  `3 VM`, `redis`, `cadvisor`, `blackbox-http`, `blackbox-tcp`) đều hiện **UP** |
| Grafana | http://localhost:3000 (tài khoản trong `.env`) | Đăng nhập bằng tài khoản trong `.env`, vào `Dashboards` -> thư mục `HKDN N4.7` -> mở **HKDN N4.7 - Host & Service Overview**, thử lọc theo biến Máy chủ, Dịch vụ, Mountpoint.  |
| Alertmanager | http://localhost:9093 | Mở giao diện kiểm tra kết nối và danh sách cảnh báo đang kích hoạt |
| cAdvisor | http://localhost:8080 | Xem chỉ số CPU, RAM của từng container đang chạy |
| Demo web (đối tượng bị giám sát) | http://localhost:8081 | Hiển thị trang mặc định của Nginx (đối tượng mẫu bị giám sát HTTP) |


Dừng lab: `docker compose down` (thêm `-v` để xóa dữ liệu metric đã lưu).


### 4. Thao tác vận hành nhanh
- **Nạp lại cấu hình Prometheus** sau khi sửa `config/prometheus.yml` hoặc `config/alert.rules.yml`:
  ```bash
  docker compose restart prometheus
  ```
- **Bật cảnh báo Telegram (tùy chọn):** Thực hiện theo hướng dẫn tại `docs/telegram-notification.md` (lưu token cục bộ trong `secrets/`, không commit lên Git).
- **Dừng toàn bộ lab:**
  ```bash
  docker compose down          # thêm -v nếu muốn xóa dữ liệu metric đã lưu
  cd vagrant && vagrant halt   # tắt 3 VM Linux
  ```

### 5. Xử lý lỗi thường gặp
- Lỗi Hay tao file .env tu .env.example khi chạy docker compose up -d: Chưa tạo file `.env`. Chạy lại `cp .env.example .env` và kiểm tra biến `GRAFANA_ADMIN_PASSWORD` không bị để trống.
- Lỗi trùng cổng (port is already allocated): Một ứng dụng khác trên máy đang dùng cổng 3000, 8080, 8081, 9090 hoặc 9093. Dừng ứng dụng đang chiếm cổng trước khi bật lab.
- Lỗi `\r: command not found` khi chạy script `.sh` trên Windows: File bị chuyển sang định dạng xuống dòng CRLF. Chạy trên WSL/Git Bash hoặc chuyển về LF bằng `sed -i 's/\r$//' <ten-file.sh>`.
- Target của 3 VM hiển thị DOWN trong Prometheus: Kiểm tra *vagrant status* để chắc chắn 3 VM đang chạy và mạng host-only `192.168.56.0/24` không bị tường lửa máy host chặn.


## Cấu trúc thư mục

*(Cập nhật sau)*
```
├── docker-compose.yml
├── .env.example
├── config/            # prometheus.yml, alert.rules.yml, alertmanager.yml, blackbox.yml
├── grafana/           # provisioning: tự nạp datasource và dashboard
├── dashboards/        # file JSON dashboard export từ Grafana
├── scenarios/         # script mô phỏng lỗi + bảng kết quả
├── docs/              # kiến trúc, runbook, mẫu biên bản họp, nhật ký góp ý PM
└── reports/           # báo cáo tuần/tháng (nếu lưu trên repo)
```

#### Tài liệu chính trong docs/:
- Phân tích & thiết kế: `docs/requirements.md`, `docs/architecture.md`, `docs/baseline_result.md`, `docs/nab_result.md`
- Triển khai & vận hành: `docs/vm-environment.md`, `docs/runbook.md`, `docs/telegram-notification.md`
- Kiểm thử & demo: `docs/integration_check.md`, `docs/demo-script.md`

## Quy tắc làm việc

1. Không commit thẳng vào `main`; làm trên nhánh `feature/<ten-viec>`.
2. Mỗi task là một issue; nhánh và commit nhắc số issue (ví dụ `#12`).
3. Xong thì mở Pull Request, cần ít nhất 1 người review (Leader review chính) rồi mới merge.
4. Commit nhỏ, thông điệp rõ (ví dụ `Thêm luật cảnh báo service down`), không dùng `fix`, `update` chung chung.
5. Dùng đúng tài khoản GitHub của mình để lịch sử phản ánh đúng đóng góp.
6. **Không commit** mật khẩu, token, webhook, IP/tên hệ thống/log thật của VNPT. Dùng `.env` (đã ignore).

## Tiêu chí nghiệm thu

- [ ] Metric được thu thập và hiển thị theo thời gian.
- [ ] Ít nhất 3 kịch bản cảnh báo được chứng minh bằng demo (CPU cao, disk đầy giả lập, service down).
- [ ] Có hướng dẫn xử lý và cách phân biệt cảnh báo giả; không dùng credential sản xuất.

## Sản phẩm bàn giao

- [ ] Sơ đồ kiến trúc giám sát (`docs/architecture.md` + `.drawio`/PNG)
- [ ] Dashboard và cấu hình cảnh báo có version control
- [ ] Bộ kịch bản lỗi và kết quả thử nghiệm (`scenarios/`)
- [ ] Runbook xử lý cảnh báo và hướng dẫn dựng lại lab (`docs/runbook.md`, README)

## Lưu ý

Nếu chạy bằng Docker Desktop (Windows/macOS), Node Exporter đo máy ảo Linux bên trong Docker chứ không phải máy thật, và cAdvisor có thể không hiện tên container ở một số panel. Dùng để học và demo thì vẫn được; muốn số liệu đúng của một máy Linux thì chạy lab trên máy hoặc VM Linux.

Các luật cảnh báo theo ngưỡng (CPU, RAM, disk) trong `config/alert.rules.yml` đang để dạng chú thích, chưa có số. Sau khi đo baseline và thống nhất với UTH, mentor VNPT thì điền ngưỡng và bật lên. Hiện chỉ có 2 luật không cần ngưỡng đang chạy: `NodeExporterDown`, `ServiceDown`.
