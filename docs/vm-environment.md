# Môi trường máy ảo (3 VM Linux đa dịch vụ)

Lab gồm **ba máy ảo Ubuntu 22.04** được dựng bằng VirtualBox + Vagrant. Prometheus, Grafana, Alertmanager và Blackbox Exporter chạy bằng Docker Compose trên máy host; Prometheus scrape ba VM qua mạng host-only.

## 1. Danh sách VM

| VM | IP host-only | Dịch vụ | Exporter / cách giám sát |
|---|---|---|---|
| `vm-web` | `192.168.56.11` | Nginx :80 | Node Exporter :9100; HTTP probe |
| `vm-db` | `192.168.56.12` | Redis :6379, MariaDB :3306 | Node Exporter :9100; Redis Exporter :9121; TCP probe Redis/MariaDB |
| `vm-app` | `192.168.56.13` | Python API :8000, `/health`, systemd `hkdn-api` | Node Exporter :9100; HTTP probe |

Mạng host-only: `192.168.56.0/24`. Cấu hình VM hiện tại: Ubuntu 22.04, mỗi VM 1 CPU và 1 GB RAM. Các gói dịch vụ được cài qua provisioning Vagrant.

## 2. Yêu cầu

- VirtualBox và Vagrant.
- Docker Desktop/Docker Engine và Docker Compose để chạy monitoring stack.
- Trên Windows, VirtualBox có thể xung đột với WSL2/Hyper-V. Nếu `vagrant up` báo lỗi ảo hóa, kiểm tra cấu hình hypervisor trước khi tiếp tục.

## 3. Dựng lab

Chạy từ thư mục gốc repository:

```bash
cd vagrant
vagrant up
vagrant status
cd ..
docker compose up -d
```

`vagrant status` cần hiển thị đủ **ba VM** (`vm-web`, `vm-db`, `vm-app`) ở trạng thái `running`.

Trên Windows PowerShell, lệnh tương đương để khởi động VM từ thư mục `vagrant`:

```powershell
Set-Location .\vagrant
vagrant up
vagrant status
Set-Location ..
docker compose up -d
```

## 4. Kiểm tra Prometheus Targets

Mở http://localhost:9090/targets. Các target chính cần kiểm tra:

| Target | Địa chỉ | Job |
|---|---|---|
| Node Exporter vm-web | `192.168.56.11:9100` | `node` |
| Node Exporter vm-db | `192.168.56.12:9100` | `node` |
| Node Exporter vm-app | `192.168.56.13:9100` | `node` |
| Redis Exporter | `192.168.56.12:9121` | `redis` |
| Nginx HTTP | `http://192.168.56.11:80` | `blackbox-http` |
| API HTTP | `http://192.168.56.13:8000/health` | `blackbox-http` |
| Redis TCP | `192.168.56.12:6379` | `blackbox-tcp` |
| MariaDB TCP | `192.168.56.12:3306` | `blackbox-tcp` |

Các target phụ trợ như `lab-host-1`, cAdvisor và `demo-web` thuộc Docker Desktop/monitoring stack, không phải một trong ba VM Linux.

Nếu Prometheus trong Docker không tới được `192.168.56.x`, kiểm tra kết nối từ máy host và trạng thái mạng host-only của VirtualBox. Không tự ý đổi IP nếu chưa cập nhật Vagrantfile, Prometheus targets và tài liệu.

## 5. Lưu ý Node Exporter và filesystem thử nghiệm

Bản Node Exporter cài bằng `apt` có thể loại trừ các mountpoint dưới `/mnt` và `/media`. Provisioning trong `vagrant/provision/common.sh` cấu hình lại `--collector.filesystem.mount-points-exclude` để filesystem thử nghiệm `/mnt/hkdn-small-disk` có thể được giám sát.

Khi đổi mountpoint thử nghiệm, cần kiểm tra đồng thời:
- Cấu hình Node Exporter trong `vagrant/provision/common.sh`.
- Biểu thức luật `DiskSpaceLow` trong `config/alert.rules.yml`.
- Script `scenarios/vm/02_disk_full_vm.sh`.

## 6. Nhãn metric

Prometheus dùng chung job `node` cho Node Exporter trong Docker và ba VM, phân biệt bằng nhãn `host`:

| Host label | Ý nghĩa |
|---|---|
| `lab-host-1` | Node Exporter phụ trợ trong Docker Desktop |
| `vm-web` | Node Exporter trên 192.168.56.11 |
| `vm-db` | Node Exporter trên 192.168.56.12 |
| `vm-app` | Node Exporter trên 192.168.56.13 |

Redis Exporter có nhãn `host="vm-db"` và `service="redis"`. Blackbox HTTP/TCP dùng nhãn `service`, `host` (nếu là VM) và `instance` (địa chỉ được probe).

## 7. Kịch bản lỗi trên VM

Chạy từ thư mục gốc repository bằng Bash (Git Bash hoặc WSL). Các script VM gọi Vagrant thông qua Windows PowerShell theo helper `scenarios/vm/lib_vm.sh`.

| Kịch bản | Lệnh | Tác động | Alert cần kiểm tra |
|---|---|---|---|
| CPU cao | `bash scenarios/vm/01_cpu_high_vm.sh` | Chạy stress-ng trên vm-web | `HighCpuUsage` |
| Disk đầy giả lập | `bash scenarios/vm/02_disk_full_vm.sh` | Tạo filesystem loop 200 MB trên vm-db, ghi khoảng 92% | `DiskSpaceLowSimulated` |
| Service down – Nginx | `bash scenarios/vm/03_service_down_vm.sh` | Dừng Nginx trên vm-web | `ServiceDown` |
| Service down – API | `bash scenarios/vm/03_service_down_vm.sh 120 vm-app hkdn-api` | Dừng systemd service hkdn-api trên vm-app | `ServiceDown` |
| CPU spike ngắn | `bash scenarios/vm/01_cpu_high_vm.sh 30` | Tạo tải CPU 30 giây | Không được chuyển sang `firing` vì `for: 2m` |

### Disk Full giả lập hoạt động như thế nào?

1. Script tạo file image ảo 200 MB trên `vm-db`.
2. Tạo filesystem ext4 và mount tại `/mnt/hkdn-small-disk`.
3. Ghi dữ liệu để mức sử dụng dung lượng đạt khoảng 92%.
4. Xuất metric `hkdn_sim_disk_used_percent` qua Node Exporter Textfile Collector.
5. Prometheus đánh giá alert `DiskSpaceLowSimulated`.
6. Script xóa metric, unmount filesystem và xóa file image sau khi thử nghiệm.

Đây là phép thử mô phỏng độc lập. Nó xác minh đường đi của metric Textfile Collector và alert `DiskSpaceLowSimulated`; **không chứng minh** luật `DiskSpaceLow` trên filesystem root `/` đã được kiểm thử thành công.

## 8. Phương pháp đo detection time và resolve time

- **Detection time:** script chỉ bắt đầu tính sau khi thao tác gây lỗi đã hoàn tất và được xác nhận. CPU bắt đầu sau khi stress-ng chạy; Service Down bắt đầu sau khi lệnh stop dịch vụ hoàn tất; Disk Full bắt đầu sau khi metric giả lập được Node Exporter đọc thành công. Script ghi `INJECT` rồi polling Prometheus API mỗi 2 giây. Thời gian kết thúc khi phát hiện alert `firing`.
- **Resolve time:** script hoàn tất thao tác khôi phục, ghi `RECOVER`, sau đó bắt đầu polling để xác nhận alert không còn `firing`. Resolve time kết thúc ở lần polling đầu tiên xác nhận alert đã hết.
- Các thời gian là kết quả đo bằng polling, độ phân giải xấp xỉ 2 giây; không phải thời gian Alertmanager gửi thông báo.

Kết quả tổng hợp ở `scenarios/results.md`, log chi tiết ở `scenarios/results/events.log`.

## 9. Lệnh vận hành VM

Từ thư mục `vagrant`:

```bash
vagrant status
vagrant halt
vagrant up
vagrant provision vm-db
vagrant ssh vm-web
vagrant ssh vm-db
vagrant ssh vm-app
```

Ví dụ dựng hoặc provision riêng một VM:

```bash
vagrant up vm-app
vagrant provision vm-db
```

## 10. Lưu ý an toàn và trạng thái

- Toàn bộ IP `192.168.56.0/24` là dải lab riêng.
- Không dùng IP, tên hệ thống, tài khoản hoặc credential thật của VNPT.
- Không đưa mật khẩu, token hoặc webhook vào Git.
- Baseline Linux VM gần nhất: 18 giờ, từ 2026-11-18 21:06 UTC đến 2026-11-19 15:06 UTC, step 60 giây, 1081 mẫu/chuỗi. Chi tiết ở `docs/baseline_result.md`.
- Các kịch bản lặp lại gần nhất: Service Down vm-web 3/3; CPU High vm-web 2/2; Disk Full giả lập vm-db 3/3. Xem `scenarios/results.md` để phân biệt kết quả mới với các lần thử lịch sử.
