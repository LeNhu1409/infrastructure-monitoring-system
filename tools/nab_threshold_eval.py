#!/usr/bin/env python3
"""Đánh giá ngưỡng cảnh báo trên chuỗi NAB (dùng để kiểm chứng phương pháp đặt ngưỡng).

Chạy:
  python nab_threshold_eval.py --nab ./NAB \
      realAWSCloudwatch/ec2_cpu_utilization_24ae8d.csv [file khác ...] > nab_result.md

Cách làm: điểm nằm trong cửa sổ bất thường (labels/combined_windows.json) là "bất thường",
còn lại là "bình thường". Ngưỡng ứng viên = các phân vị p90/p95/p99/p99.9 và max của đoạn
bình thường. Với mỗi ngưỡng, thử yêu cầu vượt liên tục N điểm (mô phỏng `for:` của luật):
  - Phát hiện: số cửa sổ bất thường có cảnh báo (vượt liên tục N điểm) bắt đầu trong cửa sổ.
  - Cảnh báo giả: số đợt cảnh báo bắt đầu ngoài cửa sổ bất thường.
Lưu ý: NAB lấy mẫu 5 phút/điểm, lab Prometheus 15 giây, nên N điểm NAB ~ N*5 phút.
"""
import argparse, json, os
import numpy as np
import pandas as pd

def episodes(mask, n):
    """Trả về chỉ số điểm bắt đầu của mỗi đợt vượt ngưỡng liên tục >= n điểm (đợt kích hoạt ở điểm thứ n)."""
    starts, run = [], 0
    for i, v in enumerate(mask):
        run = run + 1 if v else 0
        if run == n:
            starts.append(i)
    return starts

def evaluate(path, nab, ns=(1, 3)):
    df = pd.read_csv(os.path.join(nab, "data", path), parse_dates=["timestamp"])
    key = path
    windows = json.load(open(os.path.join(nab, "labels", "combined_windows.json")))[key]
    wins = [(pd.Timestamp(a), pd.Timestamp(b)) for a, b in windows]
    ts = df["timestamp"]
    in_win = np.zeros(len(df), dtype=bool)
    for a, b in wins:
        in_win |= ((ts >= a) & (ts <= b)).to_numpy()
    normal = df.loc[~in_win, "value"]
    cands = {"p90": normal.quantile(.90), "p95": normal.quantile(.95),
             "p99": normal.quantile(.99), "p99.9": normal.quantile(.999), "max": normal.max()}
    out = [f"\n### {path}\n",
           f"Số điểm: {len(df)} (bình thường {len(normal)}, trong cửa sổ bất thường {int(in_win.sum())}); "
           f"số cửa sổ bất thường: {len(wins)}; p50 bình thường = {normal.median():.3f}\n",
           "| Ngưỡng ứng viên | Giá trị | Vượt liên tục N điểm | Cửa sổ bắt được | Cảnh báo giả (đợt) |",
           "|---|---|---|---|---|"]
    vals = df["value"].to_numpy()
    for name, thr in cands.items():
        for n in ns:
            st = episodes(vals > thr, n)
            hit = sum(any(a <= ts.iloc[i] <= b for i in st) for a, b in wins)
            fp = sum(not in_win[i] for i in st)
            out.append(f"| {name} | {thr:.3f} | {n} | {hit}/{len(wins)} | {fp} |")
    return "\n".join(out)

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--nab", default="./NAB")
    ap.add_argument("files", nargs="+")
    a = ap.parse_args()
    print("## Kết quả đánh giá ngưỡng trên NAB")
    for f in a.files:
        print(evaluate(f, a.nab))
