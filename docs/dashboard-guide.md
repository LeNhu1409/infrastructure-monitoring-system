# Hướng dẫn đọc Dashboard Grafana

## Mục đích
Dashboard theo dõi máy chủ, dịch vụ, container và cảnh báo trong lab N4.7. Tệp cấu hình là `dashboards/host-service-overview.json`; dashboard dùng Prometheus, tự làm mới mỗi 30 giây và mặc định xem 6 giờ gần nhất.

## Bộ lọc và khoảng thời gian
- **Máy chủ (instance):** lọc dữ liệu host; chọn `All` để xem tất cả.
- **Dịch vụ:** lọc trạng thái kiểm tra HTTP từ Blackbox Exporter.
- **Container (id):** lọc CPU/RAM container theo nhãn `id` của cAdvisor.
- **Mountpoint:** chọn phân vùng cần xem khi panel Disk có nhiều mountpoint.
- Dùng bộ chọn thời gian của Grafana để đổi khoảng xem; có thể tạm dừng/làm mới dashboard từ thanh công cụ Grafana.

## Bố cục dashboard
### 1. Overview - Tổng quan
Bốn thẻ tóm tắt gồm trạng thái dịch vụ HTTP, uptime máy chủ, số cảnh báo đang `firing` và số target đang `UP`. Trạng thái dịch vụ `1` nghĩa là probe thành công; `0` nghĩa là probe thất bại.

### 2. Host Monitoring - Giám sát máy chủ
- **CPU sử dụng (%):** mức sử dụng CPU theo host.
- **RAM sử dụng (%):** tỷ lệ RAM đang dùng theo host.
- **Disk sử dụng (%):** dung lượng đã dùng theo mountpoint. Nếu có nhiều đường dẫn, dùng bộ lọc Mountpoint để tập trung vào phân vùng cần theo dõi.
- **Network (byte/s):** lưu lượng nhận và gửi; các thiết bị loopback và một số interface ảo bị loại khỏi truy vấn.

### 3. Service & Container Monitoring - Dịch vụ và container
Hai biểu đồ thể hiện CPU và RAM theo container. CPU được quy đổi theo phần trăm của một lõi nên có thể vượt 100% nếu container dùng nhiều lõi. RAM dùng chỉ số working set.

Trong lần kiểm tra Prometheus trước đó, bộ chọn CPU cũ `name!=""` trả về 0 chuỗi; truy vấn thử `id!=""` trả về 3 chuỗi CPU. Truy vấn RAM thử với `id!=""` trả về 7 chuỗi. Vì vậy cấu hình mới dùng nhãn `id`. Trước khi sửa, hai panel container trong Grafana hiển thị **No data**; sau khi cập nhật, cả hai panel đã có dữ liệu trên Grafana: CPU có 3 chuỗi và RAM có 7 chuỗi.

### 4. Alert Monitoring - Giám sát cảnh báo
- **Lịch sử cảnh báo - các khoảng firing:** truy vấn `ALERTS{alertstate="firing"}` chỉ biểu diễn các khoảng ở trạng thái `firing` trong dữ liệu Prometheus và khoảng thời gian được chọn. Đây không phải lịch sử đầy đủ các trạng thái pending, firing và resolved.
- **Cảnh báo đang firing:** bảng hiển thị alert đang firing tại thời điểm truy vấn. Bảng rỗng là bình thường khi hiện không có alert nào firing.
