
# DANH SÁCH METRIC THU THẬP

## 1. Giới thiệu

Tài liệu này tổng hợp các Metric được thu thập trong dự án
"Xây dựng hệ thống giám sát máy chủ, Cloud và trung tâm dữ liệu".

Hệ thống sử dụng 4 Exporter:
- Node Exporter: Thu thập thông tin CPU, RAM, Disk, Network và Uptime.
- cAdvisor: Thu thập thông tin tài nguyên và hoạt động của Docker.
- Blackbox Exporter: Kiểm tra trạng thái và khả năng truy cập của Endpoint.
- Redis Exporter: Thu thập thông tin trạng thái, bộ nhớ, kết nối và hoạt động của Redis.

Tài liệu hiện ghi nhận 25 Metric tiêu biểu từ 4 Exporter. Các Metric Node Exporter được kiểm chứng trên nhiều máy chủ, bao gồm máy chủ vm-app.

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
- Blackbox Exporter được sử dụng để kiểm tra trạng thái hoạt động và khả năng truy cập của các Endpoint.
- Trong dự án này, Blackbox Exporter được cấu hình để kiểm tra Endpoint của dịch vụ `demo-web` thông qua HTTP.

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

## 6. Redis Exporter
- Redis Exporter thu thập các metric về trạng thái, bộ nhớ, kết nối và hoạt động của Redis trên máy chủ `vm-db`.
- **Địa chỉ Exporter:** `192.168.56.12:9121`
- **Prometheus job:** `redis`
- **Host:** `vm-db`

### 6.1. Redis Status
- **Ý nghĩa:** Kiểm tra Redis có hoạt động và có thể được Exporter thu thập dữ liệu hay không.
- **Đơn vị:** Trạng thái (0 hoặc 1)
- **PromQL:**
```promql
redis_up{host="vm-db"}
```
- **Giá trị thực tế:** 1
- **Ghi chú:** Giá trị 1 cho biết Redis đang hoạt động và Exporter thu thập dữ liệu thành công.

### 6.2. Redis Memory Usage
- **Ý nghĩa:** Dung lượng bộ nhớ Redis đang sử dụng.
- **Đơn vị:** Bytes
- **PromQL:**
```promql
redis_memory_used_bytes{host="vm-db"}
```
- **Giá trị thực tế:** 873280 Bytes (khoảng 0.83 MiB)
- **Ghi chú:** Giá trị thể hiện lượng bộ nhớ Redis sử dụng tại thời điểm truy vấn.

### 6.3. Connected Clients
- **Ý nghĩa:** Số lượng client đang kết nối đến Redis.
- **Đơn vị:** Clients
- **PromQL:**
```promql
redis_connected_clients{host="vm-db"}
```
- **Giá trị thực tế:** 1
- **Ghi chú:** Có 1 client đang kết nối tại thời điểm kiểm tra.

### 6.4. Commands Processed
- **Ý nghĩa:** Tổng số lệnh Redis đã xử lý.
- **Đơn vị:** Commands
- **PromQL:**
```promql
redis_commands_processed_total{host="vm-db"}
```
- **Giá trị thực tế:** 914
- **Ghi chú:** Đây là bộ đếm tích lũy, giá trị tăng theo số lệnh Redis xử lý.

### 6.5. Cache Hits
- **Ý nghĩa:** Tổng số lần truy cập dữ liệu thành công trong Redis.
- **Đơn vị:** Hits
- **PromQL:**
```promql
redis_keyspace_hits_total{host="vm-db"}
```
- **Giá trị thực tế:** 0
- **Ghi chú:** Chưa ghi nhận lần truy cập dữ liệu thành công tại thời điểm kiểm tra.

### 6.6. Cache Misses
- **Ý nghĩa:** Tổng số lần truy cập nhưng không tìm thấy dữ liệu trong Redis.
- **Đơn vị:** Misses
- **PromQL:**

```promql
redis_keyspace_misses_total{host="vm-db"}
```
- **Giá trị thực tế:** 0
- **Ghi chú:** Chưa ghi nhận lần truy cập không tìm thấy dữ liệu tại thời điểm kiểm tra.

### 6.7. Database Keys
- **Ý nghĩa:** Số lượng key được lưu trong từng Redis Database.
- **Đơn vị:** Keys
- **PromQL:**

```promql
redis_db_keys{host="vm-db"}
```
- **Giá trị thực tế:** 0
- **Ghi chú:** Các database được kiểm tra (db0 đến db15) đều chưa có key.

### 6.8. Redis Uptime
- **Ý nghĩa:** Thời gian Redis đã hoạt động kể từ khi khởi động.
- **Đơn vị:** Seconds (s)
- **PromQL:**

```promql
redis_uptime_in_seconds{host="vm-db"}
```
- **Giá trị thực tế:** 3150 Seconds (s) (khoảng 52 phút 30 giây)
- **Ghi chú:** Thời gian hoạt động được tính từ lần khởi động Redis gần nhất.

## 7. Thu thập Metric từ máy chủ vm-app
Hệ thống sử dụng Node Exporter để thu thập các thông tin tài nguyên và trạng thái hoạt động của máy chủ vm-app tại địa chỉ `192.168.56.13:9100`. Prometheus được cấu hình scrape thông qua job `vm-app` với chu kỳ 15 giây.

### 7.1. Kết quả kiểm chứng

| STT | Nhóm Metric              | Giá trị thực tế | Đơn vị     |
|---: |    ---                   |      ---:       |   ---      |
| 1   | CPU Usage                | 51.18           | %          |
| 2   | RAM Usage                | 35.46           | %          |
| 3   | Disk Usage               | 5.64            | %          |
| 4   | Network Receive – enp0s3 | 0.47            | Bytes/s    |
| 5   | Network Receive – enp0s8 | 49.10           | Bytes/s    |
| 6   | Network Transmit – enp0s3| 0.63            | Bytes/s    |
| 7   | Network Transmit – enp0s8| 1,104.10        | Bytes/s    |
| 8   | Uptime                   | 1,605.45        | Seconds (s)|

### 7.2. Truy vấn PromQL
- CPU Usage:
  100 * (1 - avg by (host) (rate(node_cpu_seconds_total{host="vm-app", mode="idle"}[5m])))

- RAM Usage:
  100 * (1 - node_memory_MemAvailable_bytes{host="vm-app"} / node_memory_MemTotal_bytes{host="vm-app"})

- Disk Usage:
  100 * (1 - node_filesystem_avail_bytes{host="vm-app", mountpoint="/", fstype!="rootfs"} / node_filesystem_size_bytes{host="vm-app", mountpoint="/", fstype!="rootfs"})

- Network Receive:
  rate(node_network_receive_bytes_total{host="vm-app", device!="lo"}[5m])

- Network Transmit:
  rate(node_network_transmit_bytes_total{host="vm-app", device!="lo"}[5m])

- Uptime:
  node_time_seconds{host="vm-app"} - node_boot_time_seconds{host="vm-app"}


### 7.3.  Kết quả thu thập Metric từ lab-host-1 sau khi bổ sung máy chủ vm-app
- Ngoài máy chủ vm-app, hệ thống cũng ghi nhận dữ liệu Node Exporter từ máy chủ lab-host-1.
- Hệ thống tiếp tục thu thập và kiểm chứng các Metric từ máy chủ lab-host-1 thông qua Node Exporter.
- Host: lab-host-1
- Job: node
- Instance: node-exporter:9100

| STT | Nhóm Metric                 | Giá trị thực tế | Đơn vị     |
|---: |    ---                      |      ---:       |   ---      |
| 1   | CPU Usage                   |  0.6069         | %          |
| 2   | RAM Usage                   |  14.1440        | %          |
| 3   | Disk C Available            |  10,467,934,208 | Bytes      |
| 4   | Disk C Size                 |  241,286,770,688| Bytes      |
| 5   | Disk C Usage                |  95.6612        | %          |
| 6   | Network Receive Rate – eth0 |  41.6023        | Bytes/s    |
| 7   | Network Transmit Rate – eth0|  932.6563       | Bytes/s    |
| 8   | Uptime                      |  10,733.15      | Seconds (s)|

#### Các truy vấn PromQL
**1. CPU Usage**
```promql
100 * (1 - avg by (host) (rate(node_cpu_seconds_total{host="lab-host-1", mode="idle"}[5m])))
```

**2. RAM Usage**
```promql
100 * (1 - node_memory_MemAvailable_bytes{host="lab-host-1"} / node_memory_MemTotal_bytes{host="lab-host-1"})
```

**3. Disk C Available**
```promql
node_filesystem_avail_bytes{host="lab-host-1", mountpoint="/mnt/host/c"}
```

**4. Disk C Size**
```promql
node_filesystem_size_bytes{host="lab-host-1", mountpoint="/mnt/host/c"}
```

**5. Disk C Usage**
```promql
100 * (1 - node_filesystem_avail_bytes{host="lab-host-1", mountpoint="/mnt/host/c"} / node_filesystem_size_bytes{host="lab-host-1", mountpoint="/mnt/host/c"})
```

**6. Network Receive Rate**
```promql
rate(node_network_receive_bytes_total{host="lab-host-1", device="eth0"}[5m])
```

**7. Network Transmit Rate**
```promql
rate(node_network_transmit_bytes_total{host="lab-host-1", device="eth0"}[5m])
```

**8. Uptime**
```promql
node_time_seconds{host="lab-host-1"} - node_boot_time_seconds{host="lab-host-1"}
```

**Nhận xét:** Prometheus đã truy vấn thành công 8 kết quả Metric từ máy chủ `lab-host-1`, bao gồm CPU, RAM, Disk, Network và Uptime. Các giá trị phản ánh trạng thái máy chủ tại thời điểm quan sát và có thể thay đổi theo thời gian.

### 7.4. Nhận xét
Kết quả truy vấn xác nhận Prometheus đã thu thập thành công các metric từ máy chủ vm-app. Các thông tin CPU, RAM, Disk, Network và Uptime đều có dữ liệu trả về. Job `vm-app` hiển thị trạng thái UP trên giao diện Prometheus Targets.

## 8. Tổng kết
Hệ thống đã lựa chọn và ghi nhận tổng cộng 25 Metric tiêu biểu từ 4 Exporter:

| Exporter          | Số lượng Metric | Nhóm thông tin                                                      |
|     ---           |---:             |---                                                                  |
| Node Exporter     | 8               | CPU, RAM, Disk, Network, Uptime                                     |
| cAdvisor          | 6               | CPU, Memory, Network, Disk IO                                       |
| Blackbox Exporter | 3               | Endpoint, HTTP Status, Probe Duration                               |
| Redis Exporter    | 8               | Trạng thái Redis, Memory, Clients, Commands, Cache, Database, Uptime|
| **Tổng cộng**     | **25**

Các Metric được truy vấn bằng PromQL trên Prometheus và ghi nhận giá trị thực tế tại thời điểm kiểm tra. Hệ thống sử dụng Node Exporter để thu thập thông tin tài nguyên máy chủ, cAdvisor để giám sát container, Blackbox Exporter để kiểm tra Endpoint HTTP và Redis Exporter để thu thập thông tin hoạt động của Redis.

Dữ liệu thu thập được có thể sử dụng để xây dựng Dashboard, thiết lập ngưỡng cảnh báo và phân tích tình trạng hoạt động của hệ thống.
