# Môi trường máy ảo (2 VM Linux đa dịch vụ)

Theo hướng dẫn của giảng viên ("triển khai trên các máy ảo, đa dạng dịch vụ"), lab gồm ba máy ảo Ubuntu dựng bằng Vagrant. Prometheus, Grafana, Alertmanager vẫn chạy bằng Docker Compose trên máy host và scrape ba VM qua mạng riêng.

| VM | IP | Dịch vụ | Exporter / cách giám sát |
|---|---|---|---|
| `vm-web` | 192.168.56.11 | nginx (cổng 80) | Node Exporter :9100, HTTP probe |
| `vm-db` | 192.168.56.12 | Redis (6379) và MariaDB (3306), cùng nghe localhost và 192.168.56.12 | Node Exporter :9100, Redis Exporter :9121, TCP probe cổng 6379 và 3306 |
| `vm-app` | 192.168.56.13 | API Python nhỏ (cổng 8000, `/health`), chạy như dịch vụ systemd `hkdn-api` | Node Exporter :9100, HTTP probe `/health` |

Mỗi VM: 1 CPU, 1 GB RAM, box `ubuntu/jammy64`. Gói cài bằng `apt` (prometheus-node-exporter, prometheus-redis-exporter, nginx, redis-server, mariadb-server, python3, stress-ng).

## Yêu cầu
VirtualBox và Vagrant. Trên Windows, VirtualBox có thể xung đột với WSL2/Hyper-V: nếu `vagrant up` báo lỗi ảo hóa, thử bật tính năng "Windows Hypervisor Platform" hoặc chuyển sang Hyper-V/Multipass và báo lại để nhóm chỉnh Vagrantfile.

## Dựng lab
```bash
cd vagrant
vagrant up          # lần đầu tải box, mất vài phút
vagrant status      # cả hai VM ở trạng thái running
cd ..
docker compose up -d
```
Mở http://localhost:9090/targets: ngoài các target cũ phải có `192.168.56.11:9100`, `192.168.56.12:9100`, `192.168.56.12:9121`, `http://192.168.56.11:80` (job `blackbox-http`) và `192.168.56.12:6379` (job `blackbox-tcp`) ở trạng thái UP, cùng `192.168.56.13:9100`, `http://192.168.56.13:8000/health` và `192.168.56.12:3306`.

Nếu Prometheus trong Docker không tới được `192.168.56.x`: kiểm tra `ping 192.168.56.11` từ máy host trước; trên Docker Desktop, container đi ra qua máy host nên thường tới được. Nếu vẫn không, báo lại để đổi sang cách khác (ví dụ bridged network).

## Lưu ý Node Exporter của Ubuntu
Bản cài bằng `apt` mặc định loại trừ mọi mountpoint dưới `/mnt` và `/media`. `vagrant/provision/common.sh` ghi đè tham số `--collector.filesystem.mount-points-exclude` để ổ thử của kịch bản disk (`/mnt/hkdn-small-disk`) được giám sát. Nếu đổi đường dẫn ổ thử, cập nhật cả luật `DiskSpaceLow` (danh sách `mountpoint`).

## Nhãn
Metric VM dùng chung job `node` với nhãn `host=vm-web|vm-db`; dịch vụ có nhãn `service` (`nginx`, `redis`). Dashboard và luật hiện có hoạt động cho cả VM, nên khi bật luật CPU/RAM/disk thì chúng áp dụng cho mọi host.

## Kịch bản lỗi trên VM
Chạy từ thư mục gốc repo bằng bash (Windows dùng Git Bash hoặc WSL có Vagrant):

| Kịch bản | Lệnh | Tác động | Cảnh báo cần có |
|---|---|---|---|
| CPU cao | `bash scenarios/vm/01_cpu_high_vm.sh` | stress-ng trên vm-web | `HighCpuUsage` |
| Disk đầy giả lập | `bash scenarios/vm/02_disk_full_vm.sh` | ổ loop 200MB trên vm-db đầy ~92%, không đụng ổ hệ thống | `DiskSpaceLow` |
| Service down | `bash scenarios/vm/03_service_down_vm.sh` | dừng nginx trên vm-web | `ServiceDown` |
| Service down (API) | `bash scenarios/vm/03_service_down_vm.sh 120 vm-app hkdn-api` | dừng dịch vụ API trên vm-app | `ServiceDown` |
| Cảnh báo giả | `bash scenarios/vm/01_cpu_high_vm.sh 30` | CPU cao ngắn hơn `for:` | `HighCpuUsage` chỉ `pending` |

Kết quả ghi vào `scenarios/results/events.log` như các kịch bản Docker.

## Thêm VM mới hoặc cập nhật VM đang chạy
```bash
cd vagrant
vagrant up vm-app          # dựng VM mới (VM khác giữ nguyên)
vagrant provision vm-db    # chạy lại cài đặt trên VM đã có (ví dụ để thêm MariaDB)
```

## Việc cần làm sau khi có VM
- Đo lại baseline cho từng host (baseline cũ là của VM WSL2 trong Docker Desktop).
- Thêm biến chọn `host` và `service` vào dashboard.
- Sơ đồ kiến trúc và `docs/architecture.md` đã cập nhật cho 3 VM (12/11/2026); khi thêm VM hoặc dịch vụ mới thì cập nhật lại cả hai.
- Nếu muốn cảnh báo cả kiểm tra TCP (Redis, MariaDB): đổi `ServiceDown` thành `probe_success{job=~"blackbox-.*"} == 0` trong `config/alert.rules.yml` (việc của người phụ trách cảnh báo), rồi thêm kiểm thử trong `tests/`.

## Lưu ý an toàn
Toàn bộ là môi trường lab của nhóm, IP dải riêng 192.168.56.0/24. Không dùng IP, tên hệ thống hoặc credential thật của VNPT.

## Trạng thái kiểm thử
Chưa được chạy thử trên máy thật của nhóm. Người chạy đầu tiên ghi kết quả vào `docs/integration_check.md` và báo lỗi nếu có.
