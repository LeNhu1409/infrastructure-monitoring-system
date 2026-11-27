
# Runbook xử lý cảnh báo

Cách dùng: xem tên cảnh báo trên Alertmanager (`http://localhost:9093`) hoặc Grafana, rồi tìm mục tương ứng bên dưới. Lệnh dưới đây chạy trên máy/VM lab.

## Quy trình chung

1. **Xác nhận**: cảnh báo còn `firing` không? Mở dashboard "HKDN N4.7 - Host & Service Overview" xem biểu đồ quanh thời điểm cảnh báo.
2. **Khoanh vùng**: lỗi ở host, container hay dịch vụ?
3. **Xử lý** theo mục tương ứng.
4. **Ghi nhận**: giờ phát hiện, nguyên nhân, cách xử lý, giờ hết cảnh báo (ghi vào biên bản/nhật ký của nhóm).

## Kiểm tra các VM Linux

Ba VM Linux chính được quản lý bằng Vagrant. Chạy các lệnh sau từ thư mục `vagrant/`.

### Kiểm tra trạng thái VM

```bash
vagrant status
```

### Kiểm tra trạng thái dịch vụ

```bash
vagrant ssh vm-web -c "systemctl status nginx"
vagrant ssh vm-db -c "systemctl status mariadb redis-server"
vagrant ssh vm-app -c "systemctl status hkdn-api"
```

### Xem log dịch vụ

```bash
vagrant ssh vm-web -c "journalctl -u nginx -n 50 --no-pager"
vagrant ssh vm-db -c "journalctl -u mariadb -n 50 --no-pager"
vagrant ssh vm-db -c "journalctl -u redis-server -n 50 --no-pager"
vagrant ssh vm-app -c "journalctl -u hkdn-api -n 50 --no-pager"
```

### Khôi phục dịch vụ

Chỉ thực hiện sau khi xác định nguyên nhân và được nhóm thống nhất:

```bash
vagrant ssh vm-web -c "sudo systemctl restart nginx"
vagrant ssh vm-db -c "sudo systemctl restart mariadb"
vagrant ssh vm-db -c "sudo systemctl restart redis-server"
vagrant ssh vm-app -c "sudo systemctl restart hkdn-api"
```

## NodeExporterDown (critical)

- **Ý nghĩa**: Prometheus không lấy được metric của một trong ba VM trong hơn 1 phút.
- **Kiểm tra**: xem `http://localhost:9090/targets`; kiểm tra `vagrant status`; kiểm tra Node Exporter trên VM bị cảnh báo:
  `vagrant ssh <vm> -c "systemctl status prometheus-node-exporter"`.
- **Xử lý**: nếu VM đang chạy nhưng Node Exporter dừng, thử:
  `vagrant ssh <vm> -c "sudo systemctl restart prometheus-node-exporter"`.
- **Có thể là cảnh báo giả khi**: VM vừa khởi động lại hoặc đang bảo trì.

## HighCpuUsage (warning/critical)

- **Ý nghĩa**: CPU trung bình vượt ngưỡng trong khoảng thời gian được cấu hình.
- **Kiểm tra**: xác định VM từ nhãn `host` trong alert; dùng `top`, `uptime`, `ps aux --sort=-%cpu | head` để tìm tiến trình sử dụng CPU cao.
- **Xử lý**: kiểm tra tiến trình gây tải, log dịch vụ và nguyên nhân tăng tải. Chỉ dừng hoặc khởi động lại tiến trình sau khi xác định được nguyên nhân.
- **Có thể là cảnh báo giả khi**: tải tăng ngắn do khởi động dịch vụ hoặc kiểm thử. Đối chiếu thời gian `for:` và biểu đồ CPU trước khi thay đổi ngưỡng.

## HighMemoryUsage (warning/critical)

- **Ý nghĩa**: RAM sử dụng vượt ngưỡng trong khoảng thời gian được cấu hình.
- **Kiểm tra**: trên VM tương ứng, dùng `free -h`, `top` hoặc `ps aux --sort=-%mem | head`.
- **Xử lý**: xác định tiến trình sử dụng RAM cao, kiểm tra log và xu hướng sử dụng bộ nhớ. Chỉ restart dịch vụ khi đã xác định nguyên nhân.
- **Có thể là cảnh báo giả khi**: cache hệ điều hành tăng. Đánh giá dựa trên `MemAvailable`, không chỉ `MemFree`.

## DiskSpaceLow / DiskSpaceLowSimulated

- **Ý nghĩa**:
  - `DiskSpaceLow`: dung lượng filesystem root `/` trên VM vượt ngưỡng.
  - `DiskSpaceLowSimulated`: metric filesystem giả lập trên `vm-db` vượt ngưỡng; không đại diện cho root filesystem.
- **Kiểm tra disk thật**: trên VM tương ứng, dùng `df -h /` và `sudo du -xhd1 /var /home 2>/dev/null | sort -h`.
- **Kiểm tra disk giả lập**: trên `vm-db`, dùng `mountpoint /mnt/hkdn-small-disk` và kiểm tra metric `hkdn_sim_disk_used_percent`.
- **Xử lý disk thật**: tìm file/log lớn, xác định nguyên nhân tăng dung lượng rồi mới dọn dẹp. Không xóa dữ liệu tùy tiện.
- **Xử lý disk giả lập**: kiểm tra và dọn filesystem loop theo hướng dẫn trong `scenarios/vm/02_disk_full_vm.sh`.
- **Có thể là cảnh báo giả khi**: metric giả lập còn tồn tại sau kịch bản hoặc filesystem đặc biệt như `squashfs`, `tmpfs`, `loop` bị tính nhầm.

## ServiceDown (critical)

- **Ý nghĩa**: HTTP probe thất bại liên tục quá 30 giây. Luật hiện tại chỉ áp dụng cho job `blackbox-http`.
- **Kiểm tra**:
  - Xem `http://localhost:9090/targets` để xác định probe nào thất bại.
  - Nếu là Nginx: `vagrant ssh vm-web -c "systemctl status nginx"`.
  - Nếu là API: `vagrant ssh vm-app -c "systemctl status hkdn-api"`.
  - Kiểm tra endpoint bằng `curl` tới địa chỉ tương ứng được cấu hình trong `config/blackbox.yml`.
- **Xử lý**: kiểm tra log dịch vụ bằng `journalctl`, xác định nguyên nhân rồi mới restart dịch vụ.
- **Có thể là cảnh báo giả khi**: Blackbox Exporter hoặc kết nối mạng nội bộ gặp lỗi trong khi dịch vụ vẫn hoạt động.
- **Lưu ý**: Redis/MariaDB có TCP probe nhưng hiện chưa được luật `ServiceDown` bao phủ.

## Cách phân biệt cảnh báo giả

| Dấu hiệu | Khả năng | Việc làm |
|---|---|---|
| Chỉ `pending`, tự hết trước khi đủ `for:` | Tăng ngắn, đúng cơ chế giữ cảnh báo | Theo dõi; cân nhắc điều chỉnh `for:` nếu xảy ra thường xuyên |
| Nhiều cảnh báo cùng lúc, cùng giờ | Sự cố chung (mạng, Prometheus, host) hoặc vừa khởi động lại | Kiểm tra `up` và `http://localhost:9090/targets` |
| Metric có tiền tố `hkdn_sim_` | Do kịch bản giả lập | Đối chiếu `scenarios/results/events.log` |
| Cảnh báo lặp, dao động quanh ngưỡng | Ngưỡng sát giá trị thường ngày | Đo baseline, chỉnh ngưỡng hoặc `for:` |
| Cảnh báo đúng giờ bảo trì | Bảo trì có kế hoạch | Tạo silence có thời hạn trên Alertmanager |

## Lưu ý an toàn

Chỉ thao tác trên môi trường lab của nhóm. Không dùng credential sản xuất, không trỏ tới hệ thống/IP thật của VNPT. Không chạy `docker system prune` hoặc xóa filesystem khi chưa xác định rõ phạm vi ảnh hưởng.
