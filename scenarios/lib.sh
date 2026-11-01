#!/usr/bin/env bash
# Hàm dùng chung cho các kịch bản lỗi.

PROM_URL="${PROM_URL:-http://localhost:9090}"
SCENARIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCENARIO_DIR/results"
mkdir -p "$RESULTS_DIR"

now_iso() { date -u +%FT%TZ; }

# Ghi sự kiện ra màn hình và vào results/events.log (làm minh chứng).
log_event() { echo "$(now_iso) $*" | tee -a "$RESULTS_DIR/events.log"; }

require_prometheus() {
  if ! curl -fsS "$PROM_URL/-/ready" >/dev/null 2>&1; then
    echo "Không kết nối được Prometheus tại $PROM_URL. Đã chạy 'docker compose up -d' chưa?" >&2
    exit 1
  fi
}

# Trả về 0 nếu cảnh báo $1 đang ở trạng thái firing.
alert_firing() {
  local out
  out="$(curl -fsS --get --data-urlencode "query=ALERTS{alertname=\"$1\",alertstate=\"firing\"}" \
    "$PROM_URL/api/v1/query")" || return 1
  [[ "$out" != *'"result":[]'* ]]
}

# wait_for_alert <tên cảnh báo> [timeout giây]: đo thời gian từ lúc gọi đến khi firing.
wait_for_alert() {
  local name="$1" timeout="${2:-300}" start=$SECONDS
  while (( SECONDS - start < timeout )); do
    if alert_firing "$name"; then
      log_event "DETECTED alert=$name detection_time=$(( SECONDS - start ))s"
      return 0
    fi
    sleep 2
  done
  log_event "NOT_DETECTED alert=$name within ${timeout}s"
  return 1
}

# wait_for_resolved <tên cảnh báo> [timeout giây]: đo thời gian cảnh báo tự hết.
wait_for_resolved() {
  local name="$1" timeout="${2:-300}" start=$SECONDS
  while (( SECONDS - start < timeout )); do
    if ! alert_firing "$name"; then
      log_event "RESOLVED alert=$name resolve_time=$(( SECONDS - start ))s"
      return 0
    fi
    sleep 2
  done
  log_event "NOT_RESOLVED alert=$name within ${timeout}s"
  return 1
}
