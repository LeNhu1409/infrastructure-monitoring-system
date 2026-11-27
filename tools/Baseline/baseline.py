#!/usr/bin/env python3
"""Đo baseline 3 VM Linux từ Prometheus API.

Phạm vi:
- vm-web, vm-db, vm-app
- CPU, RAM, Disk root (/), Network
- HTTP probe: Web và API

Chạy:
    python baseline.py --hours 24 --out docs/baseline_result.md
"""

import argparse
import json
import math
import statistics
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

HOST_FILTER = 'job="node",host=~"vm-web|vm-db|vm-app"'

QUERIES = [
    (
        "CPU (%)",
        f'100 - avg by (host) (rate(node_cpu_seconds_total{{{HOST_FILTER},mode="idle"}}[5m])) * 100',
        "host",
    ),
    (
        "RAM (%)",
        f'(1 - node_memory_MemAvailable_bytes{{{HOST_FILTER}}} / node_memory_MemTotal_bytes{{{HOST_FILTER}}}) * 100',
        "host",
    ),
    (
        "Disk root (%)",
        f'(1 - node_filesystem_avail_bytes{{{HOST_FILTER},mountpoint="/",fstype="ext4"}} / node_filesystem_size_bytes{{{HOST_FILTER},mountpoint="/",fstype="ext4"}}) * 100',
        "host",
    ),
    (
        "Network nhận (B/s)",
        f'sum by (host) (rate(node_network_receive_bytes_total{{{HOST_FILTER},device!~"lo|veth.*|docker.*|br-.*"}}[5m]))',
        "host",
    ),
    (
        "Network gửi (B/s)",
        f'sum by (host) (rate(node_network_transmit_bytes_total{{{HOST_FILTER},device!~"lo|veth.*|docker.*|br-.*"}}[5m]))',
        "host",
    ),
    (
        "Thời gian probe HTTP (s)",
        'probe_duration_seconds{job="blackbox-http",service=~"nginx|api"}',
        "service",
    ),
    (
        "Probe HTTP thành công (1=UP)",
        'probe_success{job="blackbox-http",service=~"nginx|api"}',
        "service",
    ),
]


def query_range(prom, expr, start, end, step):
    query = urllib.parse.urlencode({
        "query": expr,
        "start": start,
        "end": end,
        "step": step,
    })

    url = f"{prom.rstrip('/')}/api/v1/query_range?{query}"

    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            data = json.load(response)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
        raise RuntimeError(f"Không thể truy vấn Prometheus: {error}") from error

    if data.get("status") != "success":
        raise RuntimeError(f"Prometheus trả về lỗi: {data}")

    return data["data"]["result"]


def pct(values, percentile):
    values = sorted(values)
    k = (len(values) - 1) * percentile
    low = int(k)
    high = min(low + 1, len(values) - 1)

    return values[low] + (
        values[high] - values[low]
    ) * (k - low)


def main():
    parser = argparse.ArgumentParser(
        description="Đo baseline tài nguyên 3 Linux VM từ Prometheus"
    )

    parser.add_argument("--prom", default="http://localhost:9090")
    parser.add_argument("--hours", type=float, default=24)
    parser.add_argument("--step", type=int, default=60)
    parser.add_argument("--out", default="baseline_result.md")

    args = parser.parse_args()

    if args.hours <= 0 or args.step <= 0:
        parser.error("--hours và --step phải lớn hơn 0")

    end = time.time()
    start = end - args.hours * 3600

    fmt = lambda timestamp: datetime.fromtimestamp(
        timestamp, timezone.utc
    ).strftime("%Y-%m-%d %H:%M UTC")

    lines = [
        "# Baseline Linux VMs - N4.7",
        "",
        f"- Khoảng đo: {fmt(start)} → {fmt(end)} ({args.hours:g} giờ)",
        f"- Chu kỳ lấy mẫu: {args.step}s",
        f"- Nguồn: Prometheus {args.prom}",
        "- Phạm vi: vm-web, vm-db, vm-app",
        "- Disk: chỉ phân vùng root (/), loại bỏ shared folder /vagrant",
        "- Trạng thái: đo trong điều kiện vận hành bình thường, không bơm lỗi",
        "",
    ]

    errors = []

    for title, expression, label in QUERIES:
        lines += [f"## {title}", ""]

        try:
            results = query_range(
                args.prom, expression, start, end, args.step
            )
        except RuntimeError as error:
            message = str(error)
            errors.append(f"{title}: {message}")
            lines += [f"> LỖI TRUY VẤN: {message}", ""]
            continue

        lines += [
            f"| {label} | Số mẫu | avg | p50 | p95 | p99 | max |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]

        if not results:
            lines += ["| Không có dữ liệu | | | | | | |", ""]
            continue

        valid_series = 0

        for series in results:
            values = []

            for sample in series.get("values", []):
                try:
                    value = float(sample[1])
                    if math.isfinite(value):
                        values.append(value)
                except (ValueError, TypeError, IndexError):
                    continue

            name = series.get("metric", {}).get(label, "-")

            if not values:
                lines.append(
                    f"| {name} | 0 | Không có dữ liệu hợp lệ | | | | |"
                )
                continue

            valid_series += 1

            lines.append(
                f"| {name} | {len(values)} "
                f"| {statistics.fmean(values):.3f} "
                f"| {pct(values, 0.50):.3f} "
                f"| {pct(values, 0.95):.3f} "
                f"| {pct(values, 0.99):.3f} "
                f"| {max(values):.3f} |"
            )

        if valid_series == 0:
            errors.append(f"{title}: Không có chuỗi dữ liệu hợp lệ")

        lines.append("")

    if errors:
        lines += [
            "## Cảnh báo về chất lượng dữ liệu",
            "",
            "Báo cáo chưa đầy đủ. Cần kiểm tra các truy vấn sau:",
            "",
        ]
        lines.extend(f"- {error}" for error in errors)
        lines.append("")

    with open(args.out, "w", encoding="utf-8") as output:
        output.write("\n".join(lines))

    print(f"Đã ghi kết quả: {args.out}")

    if errors:
        print(
            f"Có {len(errors)} lỗi hoặc truy vấn thiếu dữ liệu. "
            "Vui lòng kiểm tra báo cáo.",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
