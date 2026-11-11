# Phân tích yêu cầu hệ thống giám sát (N4.7)

> Trạng thái: **bản nháp v0.1**, nhóm cần rà soát và chờ mentor xác nhận nghiệp vụ (các câu hỏi mở ở mục 9).
> Nguồn yêu cầu: mô tả đề tài N4.7 (UTH – VNPT NET) và hướng dẫn của giảng viên. Cột "Hiện trạng" ghi theo nhánh `feature/baseline-nguong`.

## 1. Mục đích và phạm vi

**Mục đích.** Xây dựng prototype observability cho hạ tầng số trong môi trường lab kiểm soát: thu thập metric sức khỏe của máy chủ, container và dịch vụ; hiển thị thống nhất trên dashboard; phát hiện ngưỡng bất thường và minh họa cảnh báo; đo thời gian phát hiện qua các kịch bản lỗi. Đề tài không thay thế NOC/DCIM chính thức.

**Trong phạm vi**
- Môi trường lab do nhóm quản lý. Hiện là Docker Compose trên Docker Desktop (WSL2); định hướng mở rộng sang nhiều máy ảo Linux có dịch vụ đa dạng theo hướng dẫn của giảng viên.
- Theo dõi CPU, RAM, disk, network, uptime và tình trạng endpoint.
- Dashboard theo host/service, luật cảnh báo theo ngưỡng, lịch sử cảnh báo.
- Kịch bản lỗi (CPU cao, disk đầy giả lập, service down), một kịch bản cảnh báo giả, đánh giá thời gian phát hiện.
- Runbook xử lý cảnh báo và hướng dẫn dựng lại lab.

**Ngoài phạm vi**
- Kết nối nền tảng quản trị trung tâm dữ liệu thật hoặc hệ thống của VNPT khi chưa có phân quyền và phê duyệt an toàn thông tin.
- Dùng credential sản xuất, địa chỉ IP, tên hệ thống, log truy cập hay sơ đồ trung tâm dữ liệu nhạy cảm.
- Giám sát Cloud công cộng và GPU (không bắt buộc theo mô tả đề tài); tính sẵn sàng cao (HA) cho chính hệ thống giám sát.

## 2. Bên liên quan

| Vai trò | Quan tâm | Tương tác với hệ thống |
|---|---|---|
| Người vận hành (trực giám sát) | Biết ngay host hoặc dịch vụ nào bất thường và xử lý theo hướng dẫn | Dashboard, cảnh báo, runbook |
| Quản trị hạ tầng | Chỉnh ngưỡng, thêm host/dịch vụ, bảo trì lab | Cấu hình trong Git, `docker compose` |
| Giảng viên, mentor | Kiểm chứng sản phẩm đúng đề tài | Demo, báo cáo, dựng lại lab |

Các vai trò trên là giả định của nhóm, chờ mentor xác nhận.

## 3. Use case

| Mã | Tên | Tác nhân | Kết quả mong đợi |
|---|---|---|---|
| UC-01 | Xem tình trạng tổng quan host và dịch vụ | Người vận hành | Thấy trạng thái dịch vụ, CPU, RAM, disk, network, uptime trên một dashboard |
| UC-02 | Nhận cảnh báo khi vượt ngưỡng hoặc dịch vụ ngừng | Người vận hành | Cảnh báo chuyển `pending` rồi `firing` đúng điều kiện, tự hết khi hồi phục |
| UC-03 | Xử lý cảnh báo theo runbook | Người vận hành | Tìm đúng mục theo tên cảnh báo, làm theo các bước, phân biệt được cảnh báo giả |
| UC-04 | Xem lịch sử cảnh báo | Người vận hành, quản trị | Thấy các cảnh báo đã `firing` theo thời gian |
| UC-05 | Mô phỏng sự cố và đo thời gian phát hiện | Quản trị, nhóm kiểm thử | Mỗi kịch bản ghi được INJECT, DETECTED, RECOVER, RESOLVED kèm thời gian |
| UC-06 | Thêm host hoặc dịch vụ cần giám sát | Quản trị hạ tầng | Thêm target và nhãn trong cấu hình là có dữ liệu trên dashboard |
| UC-07 | Dựng lại lab từ đầu | Giảng viên, mentor, thành viên mới | Làm theo README, dựng xong và kiểm tra được bằng `docs/integration_check.md` |

## 4. Yêu cầu chức năng

| Mã | Yêu cầu | Nguồn | Thành phần | Hiện trạng |
|---|---|---|---|---|
| FR-01 | Thu thập CPU, RAM, disk, network, uptime của máy chủ | Đề tài, phạm vi | Node Exporter | Đã có, đã đo baseline 24 giờ |
| FR-02 | Thu thập metric theo container | Đề tài, mục tiêu 1 | cAdvisor | Một phần: có metric nhưng nhãn `name` rỗng trên Docker Desktop, đang thử nhãn `id` |
| FR-03 | Kiểm tra tình trạng endpoint của dịch vụ | Đề tài, phạm vi | Blackbox Exporter | Đã có (HTTP); kiểm tra TCP là hướng mở rộng |
| FR-04 | Lưu chuỗi thời gian và truy vấn lịch sử | Đề tài, tiêu chí nghiệm thu 1 | Prometheus (lưu 15 ngày) | Đã có |
| FR-05 | Dashboard theo host/service | Đề tài, phạm vi | Grafana, `dashboards/host-service-overview.json` | Một phần: 1 dashboard 12 panel, chưa có biến chọn host/service |
| FR-06 | Luật cảnh báo theo ngưỡng hai mức warning/critical, có thời gian giữ `for:` | Đề tài, mục tiêu 2 | `config/alert.rules.yml` | Một phần: luật `ServiceDown`, `NodeExporterDown` đã bật; luật CPU/RAM/disk chờ thống nhất ngưỡng |
| FR-07 | Gom nhóm và giảm nhiễu cảnh báo | Đề tài (Alertmanager nếu phù hợp) | `config/alertmanager.yml` | Đã có |
| FR-08 | Xem lịch sử cảnh báo | Đề tài, phạm vi | Panel dùng metric `ALERTS` | Đã có |
| FR-09 | Mô phỏng CPU cao, disk đầy giả lập, service down và cảnh báo giả; đo thời gian phát hiện | Đề tài, mục tiêu 3 | `scenarios/` | Một phần: có script, chưa có kết quả chính thức 3 lần |
| FR-10 | Runbook xử lý cảnh báo và cách phân biệt cảnh báo giả | Đề tài, sản phẩm bàn giao | `docs/runbook.md` | Đã có |
| FR-11 | Thông báo sự cố ra kênh ngoài (Telegram) | Nhóm đề xuất, tùy chọn | Alertmanager `telegram_configs` | Chưa làm, xem `docs/telegram-notification.md` |

## 5. Yêu cầu phi chức năng

| Mã | Yêu cầu | Cách đáp ứng hoặc kiểm tra |
|---|---|---|
| NFR-01 | Tái lập: dựng lại lab bằng ít lệnh | README, `docker compose up -d`, kiểm tra bằng `docs/integration_check.md` |
| NFR-02 | Cấu hình, dashboard, luật, kịch bản có version control | Git, Pull Request có review, CI (`.github/workflows/ci.yml`) |
| NFR-03 | An toàn: không credential sản xuất, bí mật không nằm trong Git | `.env` và `secrets/` bị ignore; không kết nối hệ thống thật |
| NFR-04 | Luật cảnh báo kiểm thử được | Kịch bản trong `scenarios/`; kiểm tra cú pháp bằng `promtool` trong CI |
| NFR-05 | Hiệu năng: chu kỳ thu thập 15 giây, chạy được trên máy host 8 đến 16 GB RAM | `config/prometheus.yml`, theo tài nguyên đề tài nêu |
| NFR-06 | Mở rộng: thêm host hoặc dịch vụ chỉ cần thêm target và nhãn | Quy ước nhãn trong `docs/architecture.md` |
| NFR-07 | Tài liệu đầy đủ theo quy trình phân tích, thiết kế, hiện thực, triển khai, thử nghiệm | Thư mục `docs/` (xem `docs/README.md`) |

## 6. Ràng buộc và giả định

- Môi trường hiện tại là Docker Desktop trên Windows (WSL2), nên số đo CPU, RAM, disk là của VM WSL2, không phải máy chủ Linux thật.
- Giảng viên hướng dẫn triển khai trên các máy ảo có dịch vụ đa dạng; nhóm đang cân nhắc mở rộng. Khi đổi môi trường, baseline cần đo lại.
- Công nghệ không bị giới hạn (theo giảng viên); nhóm chọn bộ công cụ mã nguồn mở có sẵn.
- Thời gian thực hiện 18 tuần, từ 01/11/2026 đến 06/03/2027.

## 7. Truy vết yêu cầu đến nghiệm thu

| Tiêu chí nghiệm thu của đề tài | Yêu cầu liên quan | Cách kiểm chứng | Trạng thái |
|---|---|---|---|
| Metric được thu thập và hiển thị theo thời gian | FR-01 đến FR-05 | `docs/integration_check.md` mục B (B1 đến B5), `docs/baseline_result.md` | Có dữ liệu baseline; kiểm tra chính thức chưa ghi |
| Ít nhất ba kịch bản cảnh báo chứng minh bằng demo | FR-06, FR-09 | `scenarios/results.md`, `docs/demo-script.md` | Chưa có minh chứng chính thức |
| Có hướng dẫn xử lý và phân biệt cảnh báo giả | FR-10 | `docs/runbook.md`, kịch bản cảnh báo giả | Có tài liệu; chưa có kết quả kịch bản cảnh báo giả |
| Không dùng credential sản xuất | NFR-03 | `docs/integration_check.md` bước B14 | Chưa ghi kết quả kiểm tra |

## 8. Hạn chế đã biết

Xem mục "Giới hạn đã biết" và "Hạn chế và bước tiếp theo" trong `docs/architecture.md`.

## 9. Câu hỏi mở (chờ mentor và giảng viên)

1. Ngưỡng cảnh báo và KPI thời gian phát hiện (UTH và mentor thống nhất sau khi chốt dữ liệu).
2. Bộ dữ liệu nhóm tự đo (baseline lab và NAB) đã đủ để chốt ngưỡng chưa, hay VNPT cung cấp dữ liệu tổng hợp.
3. Số máy ảo tối thiểu và các loại dịch vụ cần mô phỏng.
4. Các loại sự cố thực tế mentor mong muốn mô phỏng.
5. Mốc giữa kỳ và mẫu báo cáo đánh giá của trường (theo file hướng dẫn).
