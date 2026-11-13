BÁO CÁO KIỂM THỬ HỆ THỐNG CẢNH BÁO PROMETHUES

I.TỔNG QUAN VÀ MÔI TRƯỜNG KIỂM THỬ
 Mục tiêu: Kiểm tra độ tin cậy. Thời gian phản hồi và khả năng phát hiện sự cố của hệ thống cảnh báo promethues đối với các kịch bản lỗi thực tế và cảnh báo giả
- Thời gian thực hiện: 11/11/2026 - 13/11/2026
Môi trường hệ thống:
- Hệ điều hành Server:  [Windows Server / ubuntu Linux]
- Địa chỉ IP server: 172.31.160.1
- Phiên bản Promethues: [v2.x.x]
- Công cụ giám sát phụ trợ: windows exporter / node exporter
- Công cụ tạo tải / Gỉa lập: stress-ng, fallocate, systemclt

II.KẾT QUẢ THỰC HIỆN CÁC KỊCH BẢN KIỂM THỬ
- Kịch bản 1: CPU cao (HighCPU)
1.Mô tả kịch bản
- Mục đích: Đẩy tải CPU vượt ngưỡng cấu hình trong tệp alert_rules.yml (làm cho CPU > 80%) để kích hoạt HighCPU (INACTIVE --> FIRING)
- Phương pháp thực hiện: Sử dụng công cụ stress-ng với câu lệnh
Stress-ng--cpu 0 --timeout 3m
Sau đó nhập lệnh: 
100 * (1 - avg by(instance) (rate(windows_cpu_time_seconds_total{mode="idle"}[2m])))
Vào query của promethues để ép CPU vượt ngưỡng 80% để test
Dọn dẹp sau khi kiểm thử xong bằng lệnh: Get-Job | Stop-Job; Get-Job | Remove-Job
2.Kết quả các lần chạy ( chạy 3 lần) 

Lần chạy	Thời điểm bắt đầu tạo tải	Thời điểm chuyển sang FIRING	Thời gian phát hiện lỗi	Trạng thái
Lần 1	14:00:00	14:01:30	1m30s	đạt
Lần 2	14:18:00	14:19:30	1m30s	đạt
Lần 3	14:21:00	14:21:30	1m30s	đạt

3.Hình ảnh minh chứng



4. Nhận xét
- Cảnh báo HighCPU chuyển từ trạng thái INACTIVE --> PENDING --> FIRING đúng theo thời gian cấu hình for theo nguyên tắc

 Kịch bản 2: ổ đĩa đầy giả lập (HightDiskUsage)
1.Mô tả kịch bản: 
 - Mục đích: Tạo tệp tin dung lượng lớn để làm tăng tỷ lệ sử dụng nhân vùng ổ đĩa vượt ngưỡng cảnh báo (ex : Disk > 90%)
 - Phương pháp thực hiện : Sử dụng lệnh fallocate tạo file dung lượng lớn:
  Fallocate -1 10G /tmp/full disk test.img
 - Dọn dẹp sau khi kiểm thử xong bằng lệnh: rm /tmp/full_disk_test.img
2.Kết quả các lần chạy ( Chạy 3 lần)


Lần chạy	Thời điểm tạo ra file dung lượng	Thời điểm chuyển sang FIRING	Thời gian phát hiện lỗi	 Trạng thái
Lần 1	00:03:00	00:03:38	38s	Đạt
Lần 2	00:05:00	00:05:38	38s	Đạt
Lần 3	00:07:00	00:03:38	38s	Đạt

3.Ảnh minh chứng

4. Nhận xét 
 - Cảnh báo HighDiskUsage phản hồi chính xác khi tỷ lệ sử dụng dung lượng đĩa vượt quá ngưỡng giới hạn

Kịch bản 3: Service Down (WindowsExporterDown)
1.Mô tả kịch bản:
- Mục đích: Dừng dịch vụ exporter (windows_exporter hoặc node_exporter) để giả lập lỗi dịch vụ bị chết hoặc mất kết nối tới tiến trình thu thập metric (windows_exporter).
- Phương pháp thực hiện: Tắt dịch vụ tương ứng bằng câu lệnh :
(Sudo systemctl stop node_exporter)

2.Kết quả cho các lần chạy (Chạy 3 lần)

Lần chạy	Thời điểm tạo ra file dung lượng	Thời điểm chuyển sang FIRING	Thời gian phát hiện lỗi	 Trạng thái
Lần 1	00:10:00	00:11:06	1m6s	Đạt
Lần 2	00:13:00	00:14:06	1m6s	Đạt
Lần 3	00:17:00	00:17:06	1m6s	Đạt
 
3.Hình ảnh minh chứng

4.Nhận xét
- Hệ thống phát hiện ngay khi up==0 và phát cảnh báo trên 1 phút

Kịch bản 4: Cảnh báo giả (False Alarm Test)
1.Mô tả kịch bản
  -Mục đích: Kiểm thử quy tắc cảnh báo thủ công với biểu thức luôn đúng (vector(1) > 0)
- Phương pháp thực hiện: Sử dụng cấu hình file alert_rules,yml , sau đó reload cấu hình Promethues qua API, kiểm tra chuyển trạng thái báo động và khôi phục. 

2.Kết quả cho các lần chạy

Lần chạy	Thời điểm tạo ra file dung lượng	Thời điểm chuyển sang FIRING	Thời gian phát hiện lỗi	 Trạng thái
Lần 1	16:30:00	16:30:03	1m6s	Đạt
Lần 2	16:32:03	16:32:06	1m6s	Đạt
Lần 3	16:35:00	16:35:03	1m6s	Đạt







3.Hình ảnh minh chứng


4.Nhận xét
Tham số for trong file cấu hình quy tắc phát huy hiệu quả tốt, giúp lọc bỏ hoàn toàn các biến động tải ngắn hạn và không gây ra cảnh báo sai/cảnh báo giả.


 III. KẾT LUẬN VÀ ĐÁNH GIÁ TỔNG QUAN

Độ chính xác: Tất cả 4 kịch bản kiểm thử (với tổng cộng 12 lượt chạy) đều đạt kết quả theo kỳ vọng.

Độ ổn định: Hệ thống Prometheus Alerts bắt lỗi nhất quán giữa các lần chạy thử nghiệm khác nhau.

Khuyến nghị: Cần tiếp tục duy trì khoảng thời gian for thích hợp (từ 1m đến 3m) cho từng loại cảnh báo để cân bằng giữa tốc độ phản hồi và việc hạn chế các cảnh báo nhiễu
