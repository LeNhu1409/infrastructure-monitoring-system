# Kết quả thử nghiệm

> Điền sau mỗi lần chạy. Số liệu lấy từ `results/events.log`; ảnh minh chứng để trong `results/`.
> Chưa đặt ngưỡng đạt/không đạt: cần đo baseline rồi thống nhất với UTH và mentor VNPT.

## Môi trường thử nghiệm

- Máy/VM: ...
- HĐH, RAM, số core: ...
- Phiên bản Docker / Compose: ...
- Commit của repo khi chạy: ...

## Bảng kết quả

| Kịch bản | Lần | Ngày giờ | Cảnh báo | Thời gian phát hiện (s) | Thời gian hết cảnh báo (s) | Người thực hiện | Minh chứng | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| 1. CPU cao | 1 | | HighCpuUsage | | | | | |
| 1. CPU cao | 2 | | HighCpuUsage | | | | | |
| 1. CPU cao | 3 | | HighCpuUsage | | | | | |
| 2. Disk đầy | 1 | | DiskSpaceLow / DiskSpaceLowSimulated | | | | | |
| 2. Disk đầy | 2 | | | | | | | |
| 2. Disk đầy | 3 | | | | | | | |
| 3. Service down | 1 | | ServiceDown | | | | | |
| 3. Service down | 2 | | ServiceDown | | | | | |
| 3. Service down | 3 | | ServiceDown | | | | | |
| 4. Cảnh báo giả (CPU 30s) | 1 | | HighCpuUsage (không firing) | | | | | |

## Nhận xét

- Thời gian phát hiện trung bình / sai lệch: ...
- Cảnh báo giả đã gặp và cách xử lý: ...
- Đề xuất chỉnh ngưỡng / `for:`: ...
