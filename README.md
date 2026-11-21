# HKDN UTH – VNPT NET | Đề tài N4.7

**Xây dựng hệ thống giám sát máy chủ, Cloud và trung tâm dữ liệu**  
Nhóm 11 – Học kỳ doanh nghiệp UTH – VNPT NET (01/11/2026 – 06/03/2027)

Prototype observability trong môi trường lab kiểm soát: thu thập metric từ máy chủ và dịch vụ, trực quan hóa dashboard, đánh giá ngưỡng cảnh báo và mô phỏng sự cố. Đây là mô hình thử nghiệm phục vụ học tập, không thay thế hệ thống NOC/DCIM chính thức.

## 1. Kiến trúc triển khai hiện tại

Hệ thống gồm hai phần:

- **Monitoring stack trên máy host:** Docker Compose chạy Prometheus, Grafana, Alertmanager, Blackbox Exporter và các thành phần exporter của lab.
- **Đối tượng được giám sát:** ba máy ảo Ubuntu 22.04 chạy bằng VirtualBox + Vagrant:
  - `vm-web` – Nginx.
  - `vm-db` – Redis và MariaDB.
  - `vm-app` – Python API.

Prometheus thu thập metric từ Node Exporter trên cả ba VM qua mạng host-only `192.168.56.0/24`; Blackbox Exporter kiểm tra endpoint HTTP và TCP. Node Exporter `lab-host-1` và cAdvisor là các target phụ trợ cho môi trường Docker Desktop/container, không thay thế ba VM Linux là nhóm máy chủ chính của prototype. Chi tiết nằm trong `docs/architecture.md` và `docs/vm-environment.md`.

## 2. Công nghệ

Prometheus, Grafana, Alertmanager, Node Exporter, Redis Exporter, Blackbox Exporter, cAdvisor, Docker Compose, VirtualBox, Vagrant, Ubuntu 22.04, Python.

## 3. Yêu cầu môi trường

- Windows 11 hoặc Linux.
- Docker Desktop/Docker Engine và Docker Compose.
- VirtualBox và Vagrant để chạy ba Linux VM.
- Khuyến nghị RAM host từ 8 GB; cần đủ tài nguyên để chạy monitoring stack và ba VM đồng thời.
- Trên Windows, cấu hình ảo hóa của VirtualBox có thể xung đột với Hyper-V/WSL2. Nếu Vagrant không khởi động được VM, kiểm tra cấu hình hypervisor trước khi tiếp tục.

## 4. Dựng lab

### Bước 1 – Khởi động ba Linux VM

Chạy từ thư mục gốc repository:

```bash
cd vagrant
vagrant up
vagrant status
cd ..
```

Danh sách VM mong đợi:

| VM | IP host-only | Dịch vụ |
|---|---|---|
| vm-web | 192.168.56.11 | Nginx |
| vm-db | 192.168.56.12 | Redis, MariaDB |
| vm-app | 192.168.56.13 | Python API |

### Bước 2 – Khởi động monitoring stack

Tại thư mục gốc repository:

```bash
cp .env.example .env
# Mở .env và thay mật khẩu Grafana mặc định trước khi sử dụng.
docker compose up -d
docker compose ps
```

Trên Windows PowerShell, dùng `Copy-Item .env.example .env` thay cho lệnh `cp`.

### Bước 3 – Kiểm tra

| Thành phần | Địa chỉ |
|---|---|
| Prometheus | http://localhost:9090 |
| Prometheus Targets | http://localhost:9090/targets |
| Grafana | http://localhost:3000 |
| Alertmanager | http://localhost:9093 |
| cAdvisor | http://localhost:8080 |
| Demo web trong Docker | http://localhost:8081 |

Trong Prometheus Targets, kiểm tra Node Exporter của `vm-web`, `vm-db`, `vm-app`; Redis Exporter trên `vm-db`; HTTP probe của Nginx/API; TCP probe Redis/MariaDB; các target phụ trợ `lab-host-1` và cAdvisor nếu chúng được bật trong cấu hình.

Dừng monitoring stack: `docker compose down`.  
Dừng các VM: vào thư mục `vagrant` và chạy `vagrant halt`.  
Chỉ dùng `docker compose down -v` khi chủ động muốn xóa volume dữ liệu của Docker.

## 5. Baseline và cảnh báo hiện tại

Baseline Linux VM gần nhất được đo trong **18 giờ**, từ 2026-11-18 21:06 UTC đến 2026-11-19 15:06 UTC, bước lấy mẫu 60 giây, gồm 1081 mẫu cho mỗi chuỗi. Kết quả chi tiết ở `docs/baseline_result.md`.

Cấu hình `config/alert.rules.yml` hiện có **9 luật cảnh báo**:
- `NodeExporterDown`: mất kết nối Node Exporter của ba VM.
- `ServiceDown`: HTTP probe thất bại.
- `HighCpuUsage`: Warning 70%, Critical 90%, `for: 2m`.
- `HighMemoryUsage`: Warning 80%, Critical 90%, `for: 5m`.
- `DiskSpaceLow`: Warning 80%, Critical 90% trên filesystem root `/`, `for: 5m`.
- `DiskSpaceLowSimulated`: cảnh báo metric disk giả lập, `for: 1m`.

Các ngưỡng CPU 70/90%, RAM 80/90% và Disk 80/90% là **ngưỡng đề xuất đang dùng để thử nghiệm**, chưa phải ngưỡng vận hành cuối cùng được mentor phê duyệt. `DiskSpaceLowSimulated` là luật riêng để kiểm thử; không gộp kết quả của nó với luật `DiskSpaceLow` trên root filesystem thật. Chi tiết điều kiện xem `docs/architecture.md`.

## 6. Kịch bản kiểm thử

Các kịch bản Docker nằm trong `scenarios/`; kịch bản chạy trên Linux VM nằm trong `scenarios/vm/`.

| Kịch bản | Đối tượng | Cảnh báo |
|---|---|---|
| CPU High | vm-web | HighCpuUsage |
| Disk Full giả lập | vm-db | DiskSpaceLowSimulated |
| Service Down | Nginx trên vm-web hoặc API trên vm-app | ServiceDown |

Kịch bản Disk Full trên VM tạo filesystem loop thử nghiệm 200 MB và xuất metric `hkdn_sim_disk_used_percent` qua Node Exporter Textfile Collector. Vì vậy, kết quả xác minh luồng cảnh báo **DiskSpaceLowSimulated**, không được diễn giải thành kiểm chứng thành công luật `DiskSpaceLow` trên filesystem root thật.

**Cách tính thời gian:**
- Detection time bắt đầu sau khi thao tác gây lỗi đã hoàn tất và được xác nhận; script ghi mốc `START` ngay trước khi ghi `INJECT` và bắt đầu polling Prometheus API mỗi 2 giây. Kết thúc khi truy vấn thấy alert ở trạng thái `firing`.
- Resolve time bắt đầu sau khi script hoàn tất thao tác khôi phục và ghi `RECOVER`; kết thúc khi truy vấn thấy alert không còn `firing`.
- Đây là thời gian theo polling của script, độ phân giải xấp xỉ 2 giây; không đồng nhất với thời điểm Alertmanager gửi thông báo.

Kết quả từng lần chạy và thời gian phát hiện/khôi phục được tổng hợp tại `scenarios/results.md`; log sự kiện chi tiết tại `scenarios/results/events.log`.

## 7. Cấu trúc thư mục

```text
├── docker-compose.yml
├── .env.example
├── config/            # Prometheus, alert rules, Alertmanager, Blackbox
├── dashboards/        # Dashboard JSON
├── grafana/           # Provisioning datasource/dashboard
├── vagrant/           # Vagrantfile và provisioning cho 3 Linux VM
├── scenarios/         # Kịch bản Docker và Linux VM, kết quả kiểm thử
├── tools/             # Công cụ đo baseline và đánh giá NAB
└── docs/              # Kiến trúc, baseline, môi trường VM, runbook
```

## 8. Quy tắc làm việc

1. Không commit trực tiếp vào `main`; làm việc trên nhánh `feature/<ten-viec>`.
2. Mỗi task nên gắn với issue; nhánh và commit ghi rõ nội dung công việc.
3. Hoàn thành task thì mở Pull Request, có ít nhất một người review trước khi merge.
4. Commit nhỏ, thông điệp rõ ràng; tránh các thông điệp chung chung như `update` hoặc `fix`.
5. Không commit mật khẩu, token, webhook, credential hoặc dữ liệu nội bộ. Dùng `.env` cục bộ và giữ file này ngoài Git.

## 9. Tiêu chí nghiệm thu

- [ ] Thu thập và hiển thị metric từ các máy chủ/dịch vụ trong lab.
- [ ] Dashboard thể hiện được trạng thái và tài nguyên của ba Linux VM.
- [ ] Có minh chứng cho ít nhất ba kịch bản: CPU cao, Disk Full giả lập, Service Down.
- [ ] Có kết quả baseline, luật cảnh báo và thời gian phát hiện/khôi phục.
- [ ] Có hướng dẫn dựng lab và runbook xử lý cảnh báo.
- [ ] Không sử dụng credential hoặc dữ liệu của hệ thống sản xuất.

## 10. Sản phẩm bàn giao

- Sơ đồ kiến trúc: `docs/architecture.md` và `docs/architecture.drawio`/PNG.
- Cấu hình monitoring và dashboard: `config/`, `dashboards/`.
- Báo cáo baseline: `docs/baseline_result.md`.
- Kịch bản và kết quả thử nghiệm: `scenarios/`.
- Hướng dẫn môi trường VM: `docs/vm-environment.md`.
- Runbook và tài liệu hướng dẫn: `docs/runbook.md`.

## 11. Giới hạn cần lưu ý

- Baseline hiện tại mới có 18 giờ dữ liệu, chưa đại diện cho chu kỳ dài hạn.
- Ngưỡng tài nguyên vẫn là ngưỡng đề xuất, cần tiếp tục trao đổi với UTH và mentor VNPT.
- Disk Full trên VM hiện xác minh metric mô phỏng qua Textfile Collector; chưa thay thế bài kiểm thử luật `DiskSpaceLow` trên filesystem root thật.
- Alertmanager đang dùng receiver mặc định, chưa cấu hình gửi email/chat ra ngoài.
- cAdvisor/Node Exporter của Docker Desktop là phần giám sát phụ trợ; metric container có thể chưa đầy đủ trên môi trường Docker Desktop.
- Lab là prototype trên một máy host, chưa có HA và không kết nối hệ thống quản trị trung tâm dữ liệu thật.
