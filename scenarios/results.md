# Kết quả thử nghiệm hệ thống giám sát - N4.7

> Nguồn dữ liệu: `scenarios/results/events.log`.
> Báo cáo tổng hợp các lần kiểm thử trên Docker và Linux VM.
> Các ngưỡng tài nguyên hiện là ngưỡng đề xuất, chờ thống nhất với UTH và mentor VNPT.

## 1. Môi trường thử nghiệm

- Nền tảng: Windows 11, Docker Desktop và VirtualBox/Vagrant.
- Công cụ giám sát: Prometheus, Grafana, Alertmanager, Blackbox Exporter và Node Exporter.
- Các Linux VM:
  - `vm-web`: Nginx.
  - `vm-db`: Redis và MariaDB.
  - `vm-app`: Python API.
- Chu kỳ scrape Prometheus: 15 giây.
- Baseline gần nhất: 18 giờ, bước lấy mẫu 60 giây.
- Thời gian kiểm thử: 06/11/2026 – 21/11/2026.

### Phương pháp ghi nhận

- **Detection time:** thời gian từ lúc script bắt đầu chờ cảnh báo sau khi tạo lỗi thành công đến khi phát hiện cảnh báo ở trạng thái `firing`.
- **Resolve time:** thời gian từ khi bắt đầu khôi phục dịch vụ hoặc tài nguyên đến khi cảnh báo không còn ở trạng thái `firing`.
- Các kết quả kiểm thử lặp lại gần nhất được tổng hợp riêng, không gộp với các lần thử lịch sử có phương pháp đo hoặc cấu hình khác.
- Các lần `NOT_DETECTED` không được tính là phát hiện thành công.
- Các lần lỗi kỹ thuật trước khi xác nhận metric không được tính là lần kiểm thử cảnh báo hoàn chỉnh.

## 2. Kết quả kiểm thử trên môi trường Docker

| Kịch bản | Kết quả | Detection time | Resolve time | Ghi chú |
|---|---|---:|---:|---|
| Service Down - demo-web | Thành công | 62 giây | 18 giây | ServiceDown |
| Disk Full - textfile | Thành công | 85 giây | 26 giây | DiskSpaceLowSimulated |
| CPU High - 300 giây | Thành công | 176 giây | 24 giây | HighCpuUsage |
| CPU High - 30 giây | Không phát hiện | Trong 30 giây | Không áp dụng | Không đủ thời gian duy trì điều kiện cảnh báo |

## 3. Kết quả kiểm thử trên Linux VM

### 3.1. Kết quả lịch sử

| VM / Kịch bản | Kết quả | Detection time | Resolve time | Ghi chú |
|---|---|---:|---:|---|
| vm-web - Nginx Down | Thành công | 64 giây | 30 giây | ServiceDown |
| vm-db - Disk Full lần 1 | Không phát hiện | Trong 420 giây | Không áp dụng | Không kích hoạt DiskSpaceLow |
| vm-db - Disk Full lần 2 | Thành công | 329 giây | 39 giây | DiskSpaceLow, phát hiện chậm |
| vm-web - CPU High lần 1 | Không phát hiện | Trong 300 giây | Không áp dụng | Chưa đáp ứng điều kiện cảnh báo |
| vm-web - CPU High lần 2 | Thành công | 167 giây | 27 giây | HighCpuUsage |
| vm-web - CPU High 30 giây | Không phát hiện | Trong 30 giây | Không áp dụng | Không đủ thời gian duy trì điều kiện |
| vm-app - API Down | Thành công | 51 giây | 33 giây | ServiceDown |

### 3.2. Các đợt kiểm thử lặp lại gần nhất
Service Down và Disk Full giả lập được kiểm thử lặp lại ngày 19/11/2026; CPU High được kiểm thử bổ sung ngày 21/11/2026.
#### Service Down - vm-web (Nginx)

| Lần thử | Detection time | Resolve time | Kết quả |
|---|---:|---:|---|
| 1 | 63 giây | 30 giây | Thành công |
| 2 | 66 giây | 33 giây | Thành công |
| 3 | 65 giây | 30 giây | Thành công |
| **Trung bình** | **64,67 giây** | **31 giây** | **3/3** |

#### CPU High - vm-web

| Lần thử | Detection time | Resolve time | Kết quả |
|---|---:|---:|---|
| 1 | 169 giây | 30 giây | Thành công |
| 2 | 173 giây | 35 giây | Thành công |
| 3 | 171 giây | 31 giây | Thành công |
| **Trung bình** | **171 giây** | **32 giây** | **3/3** |

#### Disk Full giả lập - vm-db

| Lần thử | Detection time | Resolve time | Kết quả |
|---|---:|---:|---|
| 1 | 87 giây | 38 giây | Thành công |
| 2 | 84 giây | 36 giây | Thành công |
| 3 | 94 giây | 28 giây | Thành công |
| **Trung bình** | **88,33 giây** | **34 giây** | **3/3** |

Phương pháp kiểm thử Disk Full giả lập:

- Tạo file image ảo dung lượng 200 MB trên `vm-db`.
- Tạo filesystem ext4 và mount tại `/mnt/hkdn-small-disk`.
- Ghi dữ liệu để mô phỏng mức sử dụng dung lượng cao.
- Xuất metric `hkdn_sim_disk_used_percent` qua Node Exporter Textfile Collector.
- Prometheus đánh giá metric bằng cảnh báo `DiskSpaceLowSimulated`.
- Sau khi kiểm thử, script tự động xóa metric, unmount filesystem và xóa file image.

Đây là phép thử mô phỏng độc lập, không ghi đầy filesystem root của VM.

## 4. Nhận xét và đánh giá

### 4.1. Khả năng phát hiện Service Down

- Nginx trên `vm-web` được phát hiện thành công trong cả 3 lần kiểm thử lặp lại.
- Detection time dao động từ 63 đến 66 giây, trung bình 64,67 giây.
- Resolve time dao động từ 30 đến 33 giây, trung bình 31 giây.
- API trên `vm-app` cũng đã được phát hiện trong 51 giây ở lần kiểm thử lịch sử.

Kết quả cho thấy cơ chế giám sát tình trạng dịch vụ HTTP hoạt động ổn định trong các lần kiểm thử đã thực hiện.

### 4.2. Khả năng phát hiện CPU High

- Ba lần kiểm thử lặp lại gần nhất đều phát hiện `HighCpuUsage`.
- Detection time trung bình là 171 giây.
- Resolve time trung bình là 32 giây.
- Một lần kiểm thử lịch sử không phát hiện trong 300 giây.
- Kịch bản tạo tải 30 giây không kích hoạt cảnh báo. Điều này phù hợp với mục tiêu tránh cảnh báo do biến động ngắn, vì luật cảnh báo yêu cầu điều kiện duy trì trong 2 phút.

Kết quả đợt kiểm thử lặp lại gần nhất đạt 3/3 lần. Tuy nhiên, vẫn cần tiếp tục thử nghiệm trong nhiều điều kiện tải khác nhau để đánh giá độ ổn định.

### 4.3. Khả năng phát hiện Disk Full

- Hai lần kiểm thử lịch sử với cảnh báo `DiskSpaceLow` có một lần không phát hiện trong 420 giây và một lần phát hiện sau 329 giây.
- Sau khi điều chỉnh phương pháp kiểm thử sang filesystem loop và metric mô phỏng, cả 3 lần thử gần nhất đều phát hiện `DiskSpaceLowSimulated`.
- Detection time trung bình đạt 88,33 giây, dao động từ 84 đến 94 giây.
- Resolve time trung bình đạt 34 giây, dao động từ 28 đến 38 giây.
- Tỷ lệ phát hiện trong đợt kiểm thử mới đạt 3/3 lần.

Kết quả mới chứng minh được luồng phát hiện và khôi phục đối với metric dung lượng giả lập. Tuy nhiên, không nên xem đây là bằng chứng rằng cảnh báo `DiskSpaceLow` trên filesystem thật đã được xác minh hoàn toàn.

### 4.4. Đối chiếu với Baseline

Baseline 18 giờ cho thấy tài nguyên trong điều kiện đo tương đối ổn định:

- CPU p95 của ba VM khoảng 4,07–4,35%.
- RAM trung bình khoảng 36,11–43,37%.
- Disk root sử dụng trung bình khoảng 4,93–5,74%.
- HTTP probe của API và Nginx đạt tỷ lệ thành công 100% trong khoảng đo.

Các ngưỡng CPU 70/90%, RAM 80/90% và Disk 80/90% hiện là ngưỡng đề xuất để thử nghiệm. Chúng chưa phải ngưỡng tối ưu được tính toán trực tiếp từ baseline và cần được mentor xác nhận.

### 4.5. Hạn chế

- Baseline mới được thu thập trong 18 giờ, chưa đại diện đầy đủ cho chu kỳ hoạt động 24 giờ hoặc tải dài hạn.
- Chu kỳ lấy mẫu baseline là 60 giây nên có thể bỏ qua một số biến động ngắn.
- Số lần kiểm thử lặp lại của CPU High và Disk Full giả lập hiện là 3; Service Down là 3.
- Disk Full giả lập xác minh luồng cảnh báo qua metric Textfile Collector, không thay thế kiểm thử áp lực dung lượng trên filesystem root thật.
- Một số log lịch sử ghi `RESOLVED` ngay sau `NOT_DETECTED` với thời gian 0 giây do cách ghi nhận của phiên bản script cũ. Những dòng này không được xem là bằng chứng cảnh báo đã phát hiện thành công.
- Ngày 19/11 có một lần lỗi `textfile_metric_not_visible` trước khi hoàn tất điều chỉnh cách ghi metric. Đây là lỗi kỹ thuật trong quá trình chuẩn bị kiểm thử, không được tính vào ba lần kiểm thử Disk Full thành công.

## 5. Kết luận

Hệ thống đã triển khai thu thập metric từ ba Linux VM, theo dõi trạng thái dịch vụ và phát cảnh báo khi phát sinh các tình huống bất thường.

Các lần kiểm thử lặp lại gần nhất ghi nhận:

| Kịch bản | Kết quả | Detection trung bình | Resolve trung bình |
|---|---:|---:|---:|
| Service Down - vm-web | 3/3 | 64,67 giây | 31 giây |
| CPU High - vm-web | 3/3 | 171 giây | 32 giây |
| Disk Full giả lập - vm-db | 3/3 | 88,33 giây | 34 giây |

Kết quả chứng minh được luồng giám sát, phát hiện cảnh báo và khôi phục đối với ba kịch bản thử nghiệm. Trong đó, Disk Full giả lập đã được kiểm thử thành công sau khi điều chỉnh cơ chế tạo metric.

Tuy nhiên, cần phân biệt kết quả mô phỏng với kiểm thử trên filesystem thật, tiếp tục thu thập baseline dài hơn và xin mentor xác nhận các ngưỡng tài nguyên trước khi kết luận về khả năng vận hành ổn định lâu dài.

## 6. Minh chứng và tài liệu liên quan

- Log kiểm thử: `scenarios/results/events.log`.
- Báo cáo Baseline: `docs/baseline_result.md`.
- Cấu hình cảnh báo: `config/alert.rules.yml`.
- Cấu hình Prometheus: `config/prometheus.yml`.
- Dashboard: `dashboards/host-service-overview.json`.
- Kiến trúc hệ thống: `docs/architecture.md`.
- Ảnh Grafana và Alertmanager: bổ sung khi hoàn thiện bộ minh chứng.
