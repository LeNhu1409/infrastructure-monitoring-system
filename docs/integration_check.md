# Kiểm tra tích hợp end-to-end

Mục đích: chứng minh hệ thống hoạt động từ đầu đến cuối: dựng lab, thu thập metric, hiển thị dashboard, mô phỏng sự cố, phát cảnh báo và khôi phục dịch vụ.

Thực hiện sau khi các luật cảnh báo CPU/RAM/disk đã được bật trong `config/alert.rules.yml`.

Cách dùng: chạy lần lượt các bước, điền cột **Kết quả** (Đạt / Không đạt) và **Ghi chú**, đính kèm ảnh vào `scenarios/results/`. Để trống cột Kết quả nghĩa là chưa chạy.

## Thông tin lần chạy

| Mục | Giá trị |
|---|---|
| Ngày giờ | |
| Người thực hiện | |
| Commit của repo (`git rev-parse --short HEAD`) | |
| Máy / HĐH / RAM / số core | |
| Phiên bản Docker và Compose (`docker --version`, `docker compose version`) | |
| Phiên bản Vagrant (`vagrant --version`) | |

## A. Chuẩn bị (máy sạch)

```bash
git clone https://github.com/LeNhu1409/infrastructure-monitoring-system
cd infrastructure-monitoring-system
git checkout <nhánh cần kiểm tra>
cp .env.example .env        # đổi mật khẩu Grafana trong .env
docker compose up -d
```

Khởi động ba VM trong thư mục `vagrant/`:

```bash
cd vagrant
vagrant up
vagrant status
cd ..
```

Chờ khoảng 1 đến 2 phút cho các exporter có số liệu. Các script kịch bản VM được chạy bằng `bash` từ thư mục gốc repo (Windows dùng WSL).

## B. Danh sách kiểm tra

| Mã | Kiểm tra | Cách làm | Kỳ vọng | Kết quả | Ghi chú |
|---|---|---|---|---|---|
| B1 | Các container giám sát đang chạy | `docker compose ps` | 7 container `Up`: prometheus, alertmanager, grafana, node-exporter, cadvisor, blackbox, demo-web | | |
| B1a | Ba VM Linux đang chạy | `cd vagrant && vagrant status` | `vm-web`, `vm-db`, `vm-app` đều ở trạng thái `running` | | |
| B1b | Dịch vụ trên các VM hoạt động | Chạy các lệnh kiểm tra bên dưới | Nginx, MariaDB, Redis và API ở trạng thái `active` | | |
| B2 | Các target được thu thập | Mở http://localhost:9090/targets | Các job `prometheus`, `node`, `cadvisor`, `blackbox-http` có trạng thái `UP` theo cấu hình lab | | |
| B3 | Metric máy chủ có dữ liệu | Truy vấn `up{job="node"}` và `node_boot_time_seconds` trên http://localhost:9090/graph | Các target Node Exporter có giá trị `1`; metric boot time có dữ liệu | | |
| B4 | Dashboard hiển thị | Mở http://localhost:3000, dashboard "HKDN N4.7 - Host & Service Overview" | Các ô trạng thái có số liệu; panel CPU, RAM, Disk, Network có dữ liệu; ghi rõ panel nào trống | | |
| B5 | Luật cảnh báo được nạp | Mở http://localhost:9090/rules | Thấy nhóm `hkdn-availability` và `hkdn-resources` theo cấu hình, không có lỗi nạp luật | | |
| B6 | Prometheus nối được Alertmanager | `curl -s http://localhost:9090/api/v1/alertmanagers` và mở http://localhost:9093 | `activeAlertmanagers` có 1 mục; giao diện Alertmanager mở được | | |
| B7 | Kịch bản 3: Service down | `bash scenarios/vm/03_service_down_vm.sh` | `events.log` có INJECT, DETECTED (`ServiceDown`), RECOVER, RESOLVED và DONE nếu cảnh báo đã firing | | Thời gian phát hiện: ___ giây |
| B8 | Kịch bản 1: CPU cao | `bash scenarios/vm/01_cpu_high_vm.sh` | `HighCpuUsage` chuyển `firing`, sau đó được khôi phục | | Thời gian phát hiện: ___ giây |
| B9 | Kịch bản 2: Disk đầy giả lập | `bash scenarios/vm/02_disk_full_vm.sh` | `DiskSpaceLowSimulated` chuyển `firing`, sau đó được khôi phục | | Thời gian phát hiện: ___ giây |
| B10 | Kịch bản 4: CPU spike ngắn | `bash scenarios/vm/01_cpu_high_vm.sh 30` | `HighCpuUsage` chỉ ở `pending`, không chuyển `firing` | | |
| B11 | Alertmanager nhận cảnh báo | Mở http://localhost:9093 trong lúc chạy B7 đến B9 | Cảnh báo xuất hiện và được gom nhóm theo cấu hình Alertmanager | | |
| B12 | Lịch sử cảnh báo trên dashboard | Xem panel "Lịch sử cảnh báo (firing)" sau B7 đến B9 | Thấy các đợt cảnh báo tương ứng với thời điểm thử nghiệm | | |
| B13 | Dọn dẹp sau kịch bản VM | Kiểm tra trạng thái dịch vụ và tài nguyên giả lập trên các VM | Nginx được khởi động lại; không còn tiến trình stress-ng; ổ đĩa loop và metric giả lập đã được dọn | | |
| B14 | Không có bí mật trong repo | `git grep -niE "password\|token\|secret" -- . ':!docs' ':!README.md'` | Không có mật khẩu hoặc token thật; chỉ có tên biến hay chú thích | | |
| B15 | Dựng lại Docker Compose | `docker compose down -v` rồi `docker compose up -d`, lặp lại B1 đến B6 | Các thành phần Docker Compose khởi động lại và các kiểm tra liên quan đạt | | |

### Lệnh kiểm tra dịch vụ ở B1b

Chạy từ thư mục `vagrant/`:

```bash
vagrant ssh vm-web -c "systemctl is-active nginx"
vagrant ssh vm-db -c "systemctl is-active mariadb"
vagrant ssh vm-db -c "systemctl is-active redis-server"
vagrant ssh vm-app -c "systemctl is-active hkdn-api"
```

Kết quả mong đợi của mỗi lệnh là `active`.

### Lệnh kiểm tra dọn dẹp ở B13

Chạy từ thư mục `vagrant/`:

```bash
vagrant ssh vm-web -c "systemctl is-active nginx"
vagrant ssh vm-web -c "pgrep -a stress-ng || true"
vagrant ssh vm-db -c "mountpoint /mnt/hkdn-small-disk || true"
vagrant ssh vm-db -c "test ! -f /var/lib/prometheus/node-exporter/hkdn_disk.prom && echo CLEAN"
```

Nếu đã chạy kịch bản service down trên dịch vụ khác hoặc VM khác, kiểm tra đúng dịch vụ và VM đã dùng trong lần thử nghiệm.

Gợi ý xem log kịch bản từ thư mục gốc repo:

```bash
cat scenarios/results/events.log
```

## C. Lỗi và bất thường ghi nhận

| Mã | Mô tả | Mức độ | Cách xử lý hoặc kế hoạch |
|---|---|---|---|
| | | | |

## D. Kết luận

- Số mục đạt: ___ / 17
- Các mục chưa đạt và lý do:
- Người xác nhận: