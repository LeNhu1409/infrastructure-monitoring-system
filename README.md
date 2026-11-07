# HKDN UTH – VNPT NET | Đề tài N4.7

**Xây dựng hệ thống giám sát máy chủ, Cloud và trung tâm dữ liệu**

Nhóm 11 – Học kỳ doanh nghiệp UTH – VNPT NET (01/11/2026 – 06/03/2027)

Prototype quan sát (observability) trong môi trường lab kiểm soát: thu thập metric, dashboard, cảnh báo ngưỡng và mô phỏng lỗi. Không thay thế NOC/DCIM chính thức.

## Công nghệ

`Prometheus`, `Grafana`, `Alertmanager`, `Node Exporter`, `cAdvisor`, `Blackbox Exporter`, `Docker Compose`.

## Dựng lab trên máy sạch

### 1. Yêu cầu môi trường
- Máy tính cá nhân hoặc VM có RAM từ 8GB.
- Đã cài đặt Docker và Docker Compose.
- Đã cài đặt `git` và `curl`.
- **Lưu ý cho Windows:** Bắt buộc bật WSL2 backend trong Docker Desktop và sử dụng cửa sổ dòng lệnh WSL (Ubuntu) hoặc Git Bash để chạy các script `.sh` trong thư mục `scenarious/`.

### 2. Các bước khởi chạy từ đầu
```bash
git clone <link-repo>
cd infrastructure-monitoring-system
cp .env.example .env        # đổi mật khẩu Grafana trong .env tại GRAFANA_ADMIN_PASSWORD
docker compose up -d
docker compose ps
```
### 3. Kiểm tra trạng thái khi dựng lab
| Dịch vụ | Địa chỉ | Cách kiểm tra hoạt động |
|---|---|---|
| Prometheus | http://localhost:9090 | Vào mục `Status` -> `Targets`, kiểm tra cả 4 job (`prometheus`, `node`, `cadvisor`, `blackbox-http`) đều hiện **UP** |
| Grafana | http://localhost:3000 (tài khoản trong `.env`) | Đăng nhập bằng tài khoản trong `.env`, vào `Dashboards` -> thư mục `HKDN N4.7` -> mở **HKDN N4.7 - Host & Service Overview** |
| Alertmanager | http://localhost:9093 | Mở giao diện kiểm tra kết nối và danh sách cảnh báo đang kích hoạt |
| cAdvisor | http://localhost:8080 | Xem chỉ số CPU, RAM của từng container đang chạy |
| Demo web (đối tượng bị giám sát) | http://localhost:8081 | Hiển thị trang mặc định của Nginx (đối tượng mẫu bị giám sát HTTP) |

Sửa file cấu hình Prometheus (`config/prometheus.yml`, `config/alert.rules.yml`) xong thì chạy `docker compose restart prometheus` để nạp lại.

Dừng lab: `docker compose down` (thêm `-v` để xóa dữ liệu metric đã lưu).

## Cấu trúc thư mục

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
