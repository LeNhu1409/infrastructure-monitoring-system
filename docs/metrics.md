
# DANH SÁCH METRIC THU THẬP

## 1. Giới thiệu

Tài liệu này tổng hợp các Metric được thu thập trong dự án
"Xây dựng hệ thống giám sát máy chủ, Cloud và trung tâm dữ liệu".

Hệ thống sử dụng 3 Exporter:
- Node Exporter: Thu thập thông tin CPU, RAM, Disk, Network và Uptime.
- cAdvisor: Thu thập thông tin tài nguyên và hoạt động của Docker.
- Blackbox Exporter: Kiểm tra trạng thái và khả năng truy cập của Endpoint.

Tổng số Metric đã thu thập: 17 Metric.

## 2. Node Exporter

Node Exporter được sử dụng để thu thập thông tin tài nguyên
của môi trường máy chủ đang được giám sát.

### 2.1. CPU Usage

- **Ý nghĩa:** Phần trăm CPU đang sử dụng.
- **Đơn vị:** %
- **PromQL:**

```promql
100 * (1 - avg by (host) (rate(node_cpu_seconds_total{mode="idle"}[5m])))
```

- **Giá trị thực tế:** 0.923307085140512

### 2.2. Memory Usage

- **Ý nghĩa:** Phần trăm RAM đang sử dụng.
- **Đơn vị:** %
- **PromQL:**

```promql
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

- **Giá trị thực tế:** 13.5433639259181

### 2.3. Disk C Available

- **Ý nghĩa:** Dung lượng ổ C còn khả dụng.
- **Đơn vị:** Bytes
- **PromQL:**

```promql
node_filesystem_avail_bytes{mountpoint="/mnt/host/c"}
```

- **Giá trị thực tế:** 10375020544

### 2.4. Disk C Size

- **Ý nghĩa:** Tổng dung lượng ổ C.
- **Đơn vị:** Bytes
- **PromQL:**

```promql
node_filesystem_size_bytes{mountpoint="/mnt/host/c"}
```

- **Giá trị thực tế:** 241286770688

### 2.5. Disk C Usage

- **Ý nghĩa:** Phần trăm dung lượng ổ C đã sử dụng.
- **Đơn vị:** %
- **PromQL:**

```promql
100 * (1 - node_filesystem_avail_bytes{mountpoint="/mnt/host/c"} / node_filesystem_size_bytes{mountpoint="/mnt/host/c"})
```

- **Giá trị thực tế:** 95.774198582489

### 2.6. Network Receive Rate

- **Ý nghĩa:** Tốc độ nhận dữ liệu mạng trên giao diện eth0.
- **Đơn vị:** Bytes/s
- **PromQL:**

```promql
rate(node_network_receive_bytes_total{device="eth0"}[1m])
```

- **Giá trị thực tế:** 41.6018489710653

### 2.7. Network Transmit Rate

- **Ý nghĩa:** Tốc độ gửi dữ liệu mạng trên giao diện eth0.
- **Đơn vị:** Bytes/s
- **PromQL:**

```promql
rate(node_network_transmit_bytes_total{device="eth0"}[1m])
```

- **Giá trị thực tế:** 931.217636731337

### 2.8. Uptime

- **Ý nghĩa:** Thời gian hệ thống hoạt động kể từ lần khởi động gần nhất.
- **Đơn vị:** Seconds (s)
- **PromQL:**

```promql
node_time_seconds - node_boot_time_seconds
```

- **Giá trị thực tế:** 3833.55079841613


**Ghi chú:** Các giá trị trên là kết quả quan sát tại thời điểm truy vấn.
Thông tin Disk C được lấy thông qua mountpoint `/mnt/host/c`.
Các Metric Network sử dụng giao diện mạng `eth0`.



## 3. cAdvisor

cAdvisor được sử dụng để thu thập thông tin tài nguyên và hoạt động
của các Docker container, bao gồm CPU, Memory, Network và Disk I/O.

### 3.1. Docker cgroup CPU Usage

- **Ý nghĩa:** Phần trăm CPU được sử dụng bởi cgroup Docker `/docker`.
- **Đơn vị:** %
- **PromQL:**

```promql
rate(container_cpu_usage_seconds_total{cpu="total",id="/docker"}[1m]) * 100
```

- **Giá trị thực tế:** 1.0658892972

### 3.2. Docker cgroup Memory Usage

- **Ý nghĩa:** Lượng bộ nhớ đang được sử dụng bởi cgroup `/docker`.
- **Đơn vị:** Bytes
- **PromQL:**

```promql
container_memory_usage_bytes
```

- **Giá trị thực tế:** 461164544
- **Ghi chú:** Chọn kết quả có `id="/docker"`.

### 3.3. Root cgroup Network Receive Rate (eth0)

- **Ý nghĩa:** Tốc độ nhận dữ liệu mạng của root cgroup trên giao diện eth0.
- **Đơn vị:** Bytes/s
- **PromQL:**

```promql
rate(container_network_receive_bytes_total{id="/",interface="eth0"}[1m])
```

- **Giá trị thực tế:** 2293.29327084781

### 3.4. Root cgroup Network Transmit Rate (eth0)

- **Ý nghĩa:** Tốc độ gửi dữ liệu mạng của root cgroup trên giao diện eth0.
- **Đơn vị:** Bytes/s
- **PromQL:**

```promql
rate(container_network_transmit_bytes_total{id="/",interface="eth0"}[1m])
```

- **Giá trị thực tế:** 11443.0947122255

### 3.5. Docker Disk Read Rate (/dev/sdd)

- **Ý nghĩa:** Tốc độ đọc dữ liệu từ thiết bị lưu trữ `/dev/sdd` của cgroup `/docker`.
- **Đơn vị:** Bytes/s
- **PromQL:**

```promql
rate(container_fs_reads_bytes_total{id="/docker",device="/dev/sdd"}[1m])
```

- **Giá trị thực tế:** 0

### 3.6. Docker Disk Write Rate (/dev/sdd)

- **Ý nghĩa:** Tốc độ ghi dữ liệu vào thiết bị lưu trữ `/dev/sdd` của cgroup `/docker`.
- **Đơn vị:** Bytes/s
- **PromQL:**

```promql
rate(container_fs_writes_bytes_total{id="/docker",device="/dev/sdd"}[1m])
```

- **Giá trị thực tế:** 1789.7013523256

**Ghi chú:** Các Metric Network sử dụng root cgroup (`id="/"`) và giao diện mạng `eth0`. Các Metric Disk I/O sử dụng cgroup `/docker` và thiết bị `/dev/sdd`.

## 4. Lưu ý quan trọng về cAdvisor

1. **CPU và Memory:** Dữ liệu đang lấy từ cgroup `/docker`, không phải tổng CPU và RAM của toàn bộ máy tính.

2. **Network:** Hai Metric Network sử dụng root cgroup (`id="/"`) và giao diện mạng `eth0`, không phải dữ liệu riêng của từng container.

3. **Disk Read:** Giá trị bằng `0` nghĩa là trong khoảng thời gian quan sát 1 phút, Prometheus không ghi nhận tốc độ đọc dữ liệu tại cgroup và thiết bị đã chọn. Điều này không có nghĩa ổ đĩa không hoạt động.



## 5. Blackbox Exporter

Blackbox Exporter được sử dụng để kiểm tra trạng thái hoạt động và khả năng truy cập của các Endpoint.

Trong dự án này, Blackbox Exporter được cấu hình để kiểm tra Endpoint của dịch vụ `demo-web` thông qua HTTP.

### 5.1. Probe Success

- **Ý nghĩa:** Kiểm tra Endpoint có truy cập thành công hay không.
- **Đơn vị:** 0 hoặc 1
- **PromQL:**

```promql
probe_success{service="demo-web"}
```

- **Giá trị thực tế:** 1
- **Ghi chú:** Giá trị `1` nghĩa là kiểm tra thành công, `0` nghĩa là kiểm tra thất bại.

### 5.2. HTTP Status Code

- **Ý nghĩa:** Mã trạng thái HTTP trả về từ Endpoint được kiểm tra.
- **Đơn vị:** HTTP Status Code
- **PromQL:**

```promql
probe_http_status_code{service="demo-web"}
```

- **Giá trị thực tế:** 200
- **Ghi chú:** Mã `200` cho biết yêu cầu HTTP được xử lý thành công.

### 5.3. Probe Duration

- **Ý nghĩa:** Thời gian thực hiện một lần kiểm tra Endpoint.
- **Đơn vị:** Seconds (s)
- **PromQL:**

```promql
probe_duration_seconds{service="demo-web"}
```

- **Giá trị thực tế:** 0.001888976
- **Ghi chú:** Giá trị thể hiện thời gian kiểm tra Endpoint, có thể thay đổi theo từng lần đo.

## 6. Tổng kết

Hệ thống đã thu thập tổng cộng 17 Metric từ 3 Exporter:

| Exporter | Số lượng Metric | Nhóm thông tin |
|---|---:|---|
| Node Exporter | 8 | CPU, RAM, Disk, Network, Uptime |
| cAdvisor | 6 | CPU, Memory, Network, Disk I/O |
| Blackbox Exporter | 3 | Endpoint, HTTP Status, Probe Duration |
| **Tổng cộng** | **17** | |

Các Metric được truy vấn bằng PromQL trên Prometheus và ghi nhận giá trị thực tế tại thời điểm kiểm tra. Dữ liệu này có thể được sử dụng cho việc xây dựng Dashboard, thiết lập ngưỡng cảnh báo và phân tích tình trạng hoạt động của hệ thống.
