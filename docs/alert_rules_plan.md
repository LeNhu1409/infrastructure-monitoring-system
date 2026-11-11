# Luật cảnh báo và cách xác định ngưỡng

## 1. Luật cảnh báo cần có

| STT | Tên luật | Điều kiện | Mức | Ngưỡng | for | Trạng thái |
|---|---|---|---|---|---|---|
| 1 | NodeExporterDown | `up{job="node"} == 0` | critical | không cần | 1m | đang chạy |
| 2 | ServiceDown | `probe_success{job="blackbox-http"} == 0` | critical | không cần | 30s | đang chạy |
| 3 | HighCpuUsage | CPU dùng > ngưỡng | warning / critical | 70% / 90% | 2m | đã chạy thử |
| 4 | HighMemoryUsage | RAM dùng > ngưỡng | warning / critical | 80% / 90% (đề xuất) | 5m | chờ xác nhận |
| 5 | DiskSpaceLow | Disk dùng > ngưỡng | warning / critical | 80% / 90% (đề xuất) | 5m | chờ chốt mountpoint |
| 6 | DiskSpaceLowSimulated | Disk giả lập > ngưỡng | warning / critical | 80% / 90% (đề xuất) | chờ xác nhận | đã chạy thử |

- Warning và critical của cùng một luật dùng chung `alertname`, khác `severity`, để inhibit rule của Alertmanager hoạt động (đã xác nhận với HighCpuUsage).
- Network không đặt ngưỡng vì lưu lượng gần bằng 0, chưa có cơ sở.

### 1.1 Luật đề xuất thêm

| Tên luật | Điều kiện dự kiến | Lý do |
|---|---|---|
| TargetDown (cAdvisor, Prometheus) | `up == 0` | NodeExporterDown mới chỉ theo dõi job `node` |
| SlowResponse | `probe_duration_seconds` cao | Thời gian probe baseline chỉ khoảng 0,002s nên phát hiện được dịch vụ chậm |
| Cảnh báo container | metric cAdvisor | Dữ liệu container trong baseline đang trống, làm sau khi sửa truy vấn |

## 2. Cách xác định ngưỡng sau khi đo baseline

### 2.1. Baseline

Đo 24 giờ (2026-11-08 05:56 UTC → 2026-11-09 05:56 UTC), step 15s, 5761 mẫu mỗi chuỗi, bằng `tools/Baseline/baseline.py`.

| Chỉ số | avg | p95 | p99 | max |
|---|---|---|---|---|
| CPU (%) | 0,261 | 0,312 | 0,443 | 3,517 |
| RAM (%) | 15,383 | 16,150 | 16,443 | 17,091 |
| Probe thành công (1 = UP) | 1,000 | 1,000 | 1,000 | 1,000 |

Bản đo 4 giờ ngày 06/11/2026 (961 mẫu) cho kết quả tương tự: CPU max 5,736%, RAM max 15,311%.

### 2.2. Cách xác định ngưỡng

| Bước | Việc làm | Áp dụng cho lab |
|---|---|---|
| 1 | Phân loại chỉ số | `up`, `probe_success` chỉ có hai trạng thái nên không cần ngưỡng. CPU, RAM dao động nên đặt theo baseline. Disk gần như không đổi nên dùng ngưỡng tuyệt đối |
| 2 | Chọn ngưỡng | Cao hơn rõ so với max baseline. CPU: max 3,5% nên chọn 70% / 90%. RAM: max 17,1% nên chọn 80% / 90% |
| 3 | Chọn `for:` | Đủ dài để bỏ qua đợt tăng ngắn, đủ ngắn để phát hiện kịp. CPU 2m, RAM và Disk 5m |
| 4 | Kiểm tra | Chạy kịch bản và so với dữ liệu NAB (`docs/nab_result.md`). Theo ghi chép chạy thử 07/11/2026: CPU 30s không kích hoạt luật `for: 2m`, CPU 300s phát hiện sau 176s |
| 5 | Chốt số | Gửi bảng ngưỡng cho PM. Sau khi thống nhất, điền giá trị vào `alert.rules.yml`, chạy `docker compose restart prometheus` |

### 2.3. Lưu ý

- Baseline đo lúc lab gần như rảnh, chưa phản ánh tải thật.
- Disk: ổ D của máy chủ khoảng 79%, sát ngưỡng warning 80%. Luật cần giới hạn theo mountpoint của lab (ví dụ `/var/lib`, khoảng 7,6%) để tránh cảnh báo giả.
- NAB lấy mẫu 5 phút/điểm, lab 15 giây/điểm, nên chỉ dùng NAB để so sánh các cách đặt ngưỡng, không lấy số NAB làm ngưỡng cho lab.
