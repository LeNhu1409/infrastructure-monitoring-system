# Luật cảnh báo và cách xác định ngưỡng

- Nguồn: `config/alert.rules.yml`, `config/prometheus.yml`, `docs/baseline_result.md`, `scenarios/results.md`, `docs/nab_result.md`
- Ngưỡng là bản đề xuất, chưa thống nhất với PM 

## Phạm vi lab

Lab gồm 3 máy ảo Linux (Vagrant), dùng chung một bộ luật và phân biệt theo nhãn `host`

| VM | Đối tượng giám sát |
|---|---|
| vm-web | Node Exporter, HTTP probe Nginx |
| vm-db | Node Exporter, Redis Exporter, TCP probe Redis (6379) và MariaDB (3306), disk giả lập |
| vm-app | Node Exporter, HTTP probe API (`/health`) |

## 1. Luật cảnh báo cần có

| STT | Tên luật | Điều kiện | Mức | Ngưỡng | for | Phạm vi | Trạng thái |
|---|---|---|---|---|---|---|---|
| 1 | NodeExporterDown | `up{job="node"} == 0` | critical | không cần | 1m | 3 VM | đã bật |
| 2 | ServiceDown | `probe_success{job="blackbox-http"} == 0` | critical | không cần | 30s | HTTP: demo-web, Nginx, API | đã bật, đã kiểm thử, chưa phủ TCP |
| 3 | HighCpuUsage | CPU dùng > ngưỡng | warning / critical | 70% / 90% | 2m | 3 VM | đã bật, đã kiểm thử |
| 4 | HighMemoryUsage | RAM dùng > ngưỡng | warning / critical | 80% / 90% | 5m | 3 VM | đã bật, chưa có kịch bản |
| 5 | DiskSpaceLow | Disk `/` (ext4) dùng > ngưỡng | warning / critical | 80% / 90% | 5m | 3 VM | đã bật, chưa xác minh đầy đủ trên filesystem thật |
| 6 | DiskSpaceLowSimulated | `hkdn_sim_disk_used_percent` > ngưỡng | warning | 80% | 1m | vm-db | đã bật, đã kiểm thử |

- Warning và critical của cùng một luật dùng chung `alertname`, khác `severity`, để inhibit rule của Alertmanager hoạt động (áp dụng cho CPU, RAM, Disk)
- Network không đặt ngưỡng vì lưu lượng thấp và biến động lớn (max nhận đến 113.279 B/s so với p95 khoảng 77 B/s), chưa có cơ sở

### 1.1 Luật đề xuất thêm

| Tên luật | Điều kiện dự kiến | Lý do |
|---|---|---|
| ServiceDown cho TCP | đổi biểu thức thành `probe_success{job=~"blackbox-.*"} == 0` | Job `blackbox-tcp` (Redis, MariaDB) chưa có cảnh báo |
| RedisExporterDown | `up{job="redis"} == 0` | Job `redis` chưa có cảnh báo mất kết nối |
| DiskSpaceLowSimulated mức critical | `hkdn_sim_disk_used_percent > 90` | Luật hiện chỉ có mức warning |
| Cảnh báo container | metric cAdvisor | Dữ liệu container chưa ổn định, làm sau khi sửa truy vấn |

## 2. Cách xác định ngưỡng sau khi đo baseline

### 2.1. Baseline lab 3 VM

- Khoảng đo: 2026-11-18 21:06 UTC → 2026-11-19 15:06 UTC (18 giờ)
- Chu kỳ lấy mẫu 60s, 1081 mẫu mỗi chuỗi, điều kiện vận hành bình thường, không bơm lỗi
- Disk chỉ tính phân vùng root (`/`), loại bỏ shared folder `/vagrant`

| host | CPU avg (%) | CPU p95 (%) | CPU max (%) | RAM avg (%) | RAM max (%) | Disk root avg (%) | Disk root max (%) |
|---|---:|---:|---:|---:|---:|---:|---:|
| vm-app | 3,483 | 4,073 | 13,744 | 36,661 | 37,343 | 4,955 | 4,966 |
| vm-db | 3,756 | 4,351 | 12,764 | 43,365 | 43,935 | 5,743 | 5,758 |
| vm-web | 3,639 | 4,220 | 13,712 | 36,112 | 36,847 | 4,934 | 5,297 |

HTTP probe của API và Nginx thành công 100% trong khoảng đo, thời gian probe trung bình 0,004s.

### 2.2. Cách xác định ngưỡng

| Bước | Việc làm | Áp dụng cho lab |
|---|---|---|
| 1 | Phân loại chỉ số | `up`, `probe_success` chỉ có hai trạng thái nên không cần ngưỡng. CPU, RAM dao động nên đặt theo baseline. Disk gần như không đổi nên dùng ngưỡng tuyệt đối |
| 2 | Chọn ngưỡng | Cao hơn rõ so với max baseline. CPU: max 13,7% nên chọn 70% / 90%. RAM: max 43,9% nên chọn 80% / 90%. Disk root: max 5,8% nên chọn 80% / 90% theo mức nguy hiểm thực tế |
| 3 | Chọn `for:` | Đủ dài để bỏ qua đợt tăng ngắn, đủ ngắn để phát hiện kịp. CPU 2m, RAM và Disk 5m |
| 4 | Kiểm tra | Chạy kịch bản trên VM (bảng 2.3). Kịch bản CPU 30 giây không kích hoạt cảnh báo, phù hợp với `for: 2m` |
| 5 | Chốt số | Gửi bảng ngưỡng cho PM. Sau khi thống nhất, điền giá trị vào `alert.rules.yml`, chạy `docker compose restart prometheus` |

Các ngưỡng hiện là ngưỡng đề xuất để thử nghiệm, chưa được tính trực tiếp từ baseline và cần được mentor xác nhận.

### 2.3. Kết quả kiểm thử trên VM

Các đợt lặp lại gần nhất (Service Down, Disk Full giả lập ngày 19/11/2026; CPU High ngày 21/11/2026), nguồn `scenarios/results.md`:

| Kịch bản | Luật | Detection (giây) | Trung bình | Kết quả |
|---|---|---|---:|---|
| Service Down, vm-web (Nginx) | ServiceDown | 63, 66, 65 | 64,67 | 3/3 |
| CPU High, vm-web | HighCpuUsage | 169, 173, 171 | 171 | 3/3 |
| Disk Full giả lập, vm-db | DiskSpaceLowSimulated | 87, 84, 94 | 88,33 | 3/3 |

Thời gian phát hiện của CPU (171 giây) lớn hơn `for: 2m` (120 giây) do còn chu kỳ lấy mẫu và đánh giá luật.

### 2.4. Lưu ý

- Baseline mới 18 giờ, chu kỳ 60 giây, chưa đại diện đầy đủ cho chu kỳ 24 giờ hoặc tải dài hạn
- Kịch bản Disk Full giả lập xác minh luồng cảnh báo qua metric textfile. Hai lần thử lịch sử với `DiskSpaceLow` trên filesystem thật có một lần không phát hiện trong 420 giây và một lần phát hiện sau 329 giây, nên luật này chưa được xem là xác minh hoàn toàn
- Luật RAM chưa có kịch bản kiểm thử
- NAB lấy mẫu 5 phút/điểm, lab 15 giây/điểm, nên chỉ dùng NAB để so sánh các cách đặt ngưỡng, không lấy số NAB làm ngưỡng cho lab

## 3. Việc tiếp theo

- Đề xuất Leader mở rộng ServiceDown cho TCP (Redis, MariaDB)
- Thêm kịch bản kiểm thử cho luật RAM và DiskSpaceLow trên filesystem thật
- Thống nhất ngưỡng với PM
