
# Kịch bản lỗi và kiểm thử

Các kịch bản được thực hiện trên 3 VM Linux bằng Vagrant. Script tự đo thời gian phát hiện (từ lúc gây lỗi đến khi cảnh báo chuyển sang `firing`) và ghi kết quả vào `scenarios/results/events.log`.

## Điều kiện trước khi chạy

- Docker Compose monitoring stack đang chạy: `docker compose up -d`.
- Ba VM đã khởi động. Từ thư mục `vagrant/`, chạy `vagrant status`.
- Prometheus, Grafana và Alertmanager truy cập được.
- Chạy script từ thư mục gốc repository bằng Bash (Windows sử dụng WSL).

## Danh sách kịch bản

| # | Kịch bản | Lệnh | Cảnh báo kỳ vọng | Điều kiện |
|---|---|---|---|---|
| 1 | CPU cao trên vm-web | `bash scenarios/vm/01_cpu_high_vm.sh` | `HighCpuUsage` | Luật CPU đã bật |
| 2 | Disk đầy giả lập trên vm-db | `bash scenarios/vm/02_disk_full_vm.sh` | `DiskSpaceLowSimulated` | Luật disk giả lập đã bật |
| 3 | Service down trên vm-web | `bash scenarios/vm/03_service_down_vm.sh` | `ServiceDown` | Luật ServiceDown đã bật |
| 4 | CPU spike ngắn trên vm-web | `bash scenarios/vm/01_cpu_high_vm.sh 30` | Không chuyển sang `firing`; dự kiến chỉ `pending` | Luật CPU đã bật |

**Lưu ý về disk:** Kịch bản số 2 sử dụng filesystem loop 200 MB và metric textfile giả lập trên `vm-db`. Đây không phải thao tác làm đầy phân vùng root `/` thật và cảnh báo mong đợi là `DiskSpaceLowSimulated`, không phải `DiskSpaceLow`.

Thời gian phát hiện thực tế lấy từ `scenarios/results/events.log`. Kịch bản CPU và disk cần bật luật tương ứng trong `config/alert.rules.yml`. Kịch bản ServiceDown cần endpoint HTTP được cấu hình trong Blackbox Exporter hoạt động.

## Cách ghi kết quả

1. Mở Grafana tại `http://localhost:3000` và Alertmanager tại `http://localhost:9093`.
2. Chạy từng script, chụp ảnh hoặc quay màn hình lúc cảnh báo xuất hiện và lúc hồi phục.
3. Đối chiếu các dòng `INJECT`, `DETECTED`, `RECOVER`, `RESOLVED` trong `scenarios/results/events.log`.
4. Tổng hợp kết quả vào `scenarios/results.md`.
5. Mỗi kịch bản nên chạy ít nhất 3 lần để đánh giá tính ổn định và thời gian phát hiện.

## An toàn và dọn dẹp

- Chỉ chạy trên các VM lab của nhóm. Không trỏ tới hệ thống thật của VNPT.
- Script có cơ chế dọn dẹp sau khi chạy. Nếu bị ngắt giữa chừng, kiểm tra trạng thái trước khi chạy lại.
- Kiểm tra tiến trình stress-ng trên `vm-web`:
  `vagrant ssh vm-web -c "pgrep -a stress-ng || true"`
- Kiểm tra filesystem giả lập trên `vm-db`:
  `vagrant ssh vm-db -c "mountpoint /mnt/hkdn-small-disk"`
- Kiểm tra metric giả lập:
  `vagrant ssh vm-db -c "sudo ls -l /var/lib/prometheus/node-exporter/hkdn_disk.prom"`
- Nếu cần dọn thủ công, chỉ thực hiện sau khi xác nhận đúng VM và đúng filesystem giả lập.
