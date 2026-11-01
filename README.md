# HKDN UTH – VNPT NET | Đề tài N4.7

**Xây dựng hệ thống giám sát máy chủ, Cloud và trung tâm dữ liệu**
Nhóm 11 – Học kỳ doanh nghiệp UTH – VNPT NET (01/11/2026 – 06/03/2027)

Prototype quan sát (observability) trong môi trường lab kiểm soát: thu thập metric, dashboard, cảnh báo ngưỡng và mô phỏng lỗi. Không thay thế NOC/DCIM chính thức.

## Công nghệ

Prometheus, Grafana, Alertmanager, Node Exporter, cAdvisor, Blackbox Exporter, Docker Compose.

## Dựng lab

Yêu cầu: Docker và Docker Compose (khuyến nghị Linux hoặc WSL2), RAM host từ 8 GB.

```bash
git clone <link-repo>
cd infrastructure-monitoring-system
cp .env.example .env        # đổi mật khẩu Grafana trong .env
docker compose up -d
docker compose ps
```

| Dịch vụ | Địa chỉ |
|---|---|
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 (tài khoản trong `.env`) |
| Alertmanager | http://localhost:9093 |
| cAdvisor | http://localhost:8080 |
| Demo web (đối tượng bị giám sát) | http://localhost:8081 |

Dừng lab: `docker compose down` (thêm `-v` để xóa dữ liệu).

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

Các luật cảnh báo theo ngưỡng (CPU, RAM, disk) trong `config/alert.rules.yml` đang để dạng chú thích, chưa có số. Sau khi đo baseline và thống nhất với UTH, mentor VNPT thì điền ngưỡng và bật lên. Hiện chỉ có 2 luật không cần ngưỡng đang chạy: `NodeExporterDown`, `ServiceDown`.
