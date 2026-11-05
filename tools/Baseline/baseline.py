#!/usr/bin/env python3
"""Đo baseline từ Prometheus API (chỉ dùng thư viện chuẩn, không cần cài thêm).

Chạy (lab đã chạy bình thường, CHƯA bơm lỗi, tối thiểu 24h):
  python baseline.py --hours 24 --out baseline_result.md
Tùy chọn: --prom http://localhost:9090  --step 60

Dùng đúng biểu thức của dashboard host-service-overview.json để số đo khớp với những gì hiển thị.
"""
import argparse, json, statistics, time, urllib.parse, urllib.request
from datetime import datetime, timezone

DISK_FS = 'fstype!~"tmpfs|overlay|squashfs|ramfs|devtmpfs|fuse.*|nsfs"'
QUERIES = [
    ("CPU (%)", '100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)', "instance"),
    ("RAM (%)", '(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100', "instance"),
    ("Disk (%)", f'(1 - node_filesystem_avail_bytes{{{DISK_FS}}} / node_filesystem_size_bytes{{{DISK_FS}}}) * 100', "mountpoint"),
    ("Network nhận (B/s)", 'sum by (instance) (rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*|br-.*"}[1m]))', "instance"),
    ("Network gửi (B/s)", 'sum by (instance) (rate(node_network_transmit_bytes_total{device!~"lo|veth.*|docker.*|br-.*"}[1m]))', "instance"),
    ("Thời gian probe (s)", 'probe_duration_seconds{job="blackbox-http"}', "service"),
    ("Probe thành công (1=UP)", 'probe_success{job="blackbox-http"}', "service"),
    ("CPU theo container (%)", 'sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[1m])) * 100', "name"),
    ("RAM theo container (MB)", 'sum by (name) (container_memory_working_set_bytes{name!=""}) / 1024 / 1024', "name"),
]

def query_range(prom, expr, start, end, step):
    q = urllib.parse.urlencode({"query": expr, "start": start, "end": end, "step": step})
    with urllib.request.urlopen(f"{prom}/api/v1/query_range?{q}", timeout=60) as r:
        d = json.load(r)
    if d.get("status") != "success":
        raise RuntimeError(d)
    return d["data"]["result"]

def pct(vals, p):
    s = sorted(vals)
    k = (len(s) - 1) * p
    lo, hi = int(k), min(int(k) + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (k - lo)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prom", default="http://localhost:9090")
    ap.add_argument("--hours", type=float, default=24)
    ap.add_argument("--step", type=int, default=60)
    ap.add_argument("--out", default="baseline_result.md")
    a = ap.parse_args()
    end = time.time()
    start = end - a.hours * 3600
    fmt = lambda t: datetime.fromtimestamp(t, timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [f"# Baseline lab N4.7", "",
             f"- Khoảng đo: {fmt(start)} → {fmt(end)} ({a.hours:g} giờ), step {a.step}s",
             f"- Nguồn: Prometheus {a.prom}; biểu thức lấy từ dashboard host-service-overview", ""]
    for title, expr, label in QUERIES:
        try:
            res = query_range(a.prom, expr, start, end, a.step)
        except Exception as e:
            lines += [f"## {title}", f"Lỗi truy vấn: {e}", ""]
            continue
        lines += [f"## {title}", "", f"| {label} | Số mẫu | avg | p50 | p95 | p99 | max |", "|---|---|---|---|---|---|---|"]
        if not res:
            lines += ["| (không có dữ liệu) | | | | | | |", ""]
            continue
        for s in res:
            v = [float(x[1]) for x in s["values"] if x[1] not in ("NaN", "+Inf", "-Inf")]
            if not v:
                continue
            name = s["metric"].get(label, "-")
            lines.append(f"| {name} | {len(v)} | {statistics.fmean(v):.3f} | {pct(v,.5):.3f} | {pct(v,.95):.3f} | {pct(v,.99):.3f} | {max(v):.3f} |")
        lines.append("")
    open(a.out, "w", encoding="utf-8").write("\n".join(lines))
    print(f"Đã ghi {a.out}")

if __name__ == "__main__":
    main()
