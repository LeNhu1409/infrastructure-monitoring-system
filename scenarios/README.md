# Kịch bản lỗi và kiểm thử

Mỗi kịch bản gây lỗi có kiểm soát trong lab, tự đo **thời gian phát hiện** (từ lúc gây lỗi đến khi cảnh báo chuyển sang `firing`) và ghi vào `results/events.log`.

Điều kiện: lab đang chạy (`docker compose up -d`), có `curl`, chạy script bằng `bash` (Windows dùng WSL).

| # | Kịch bản | Lệnh | Cảnh báo kỳ vọng | Cần bật luật trước? |
|---|---|---|---|---|
| 1 | CPU cao | `bash scenarios/01_cpu_high.sh` | `HighCpuUsage` | Có (sau baseline) |
| 2a | Disk đầy (ổ 200MB thật, cần sudo) | `bash scenarios/02_disk_full.sh loop` | `DiskSpaceLow` | Có (sau baseline) |
| 2b | Disk đầy (metric giả lập) | `bash scenarios/02_disk_full.sh textfile` | `DiskSpaceLowSimulated` | Có (sau baseline) |
| 3 | Service down | `bash scenarios/03_service_down.sh` | `ServiceDown` | Không, đã bật sẵn |
| 4 | Cảnh báo giả (tăng CPU ngắn) | `bash scenarios/01_cpu_high.sh 30` | không có (chỉ `pending`) | Có (sau baseline) |

Thời gian phát hiện thật lấy từ `results/events.log`. Kịch bản 1, 2, 4 chỉ cho kết quả sau khi nhóm đã đo baseline và bật luật tương ứng trong `config/alert.rules.yml`; trước đó script sẽ ghi `NOT_DETECTED`. Có thể chạy kịch bản 3 ngay vì luật `ServiceDown` không cần ngưỡng.

Docker Desktop (Windows/macOS): dùng chế độ `textfile` cho kịch bản 2 (script tự chuyển nếu phát hiện).

## Cách ghi kết quả

1. Trước khi chạy: mở Grafana (http://localhost:3000) và Alertmanager (http://localhost:9093).
2. Chạy script, **chụp ảnh/quay màn hình** lúc cảnh báo lên và lúc hết.
3. Chép các dòng `INJECT / DETECTED / RECOVER / RESOLVED` từ `results/events.log` vào `results.md`.
4. Mỗi kịch bản nên chạy ít nhất 3 lần để lấy giá trị trung bình; lưu ảnh vào `results/` (đặt tên `kichban1_lan1.png`...).

## An toàn

- Chỉ chạy trên máy/VM lab của nhóm. Không trỏ tới hệ thống thật của VNPT.
- Kịch bản 2 không đụng tới ổ đĩa thật: chế độ `loop` dùng file `.img` riêng và tự dọn khi kết thúc; chế độ `textfile` chỉ ghi một file metric giả.
- Nếu script bị ngắt giữa chừng, chạy lại để tự dọn, hoặc dọn tay: `docker rm -f hkdn-stress-cpu`, `docker start hkdn-demo-web`, `sudo umount /mnt/hkdn-small-disk`, `rm -f scenarios/textfile/sim_disk.prom`.
