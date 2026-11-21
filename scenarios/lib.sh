#!/usr/bin/env bash
# Hàm dùng chung cho các kịch bản lỗi.

PROM_URL="${PROM_URL:-http://localhost:9090}"
_SCENARIO_LIB_SOURCE="${BASH_SOURCE[0]}"
SCENARIO_DIR="$(cd -- "$(dirname -- "$_SCENARIO_LIB_SOURCE")" && pwd)"
RESULTS_DIR="$SCENARIO_DIR/results"
mkdir -p "$RESULTS_DIR"

now_iso() {
  date -u +%FT%TZ
}

# Ghi sự kiện ra màn hình và vào results/events.log.
log_event() {
  echo "$(now_iso) $*" | tee -a "$RESULTS_DIR/events.log"
}

require_prometheus() {
  if ! curl -fsS "$PROM_URL/-/ready" >/dev/null 2>&1; then
    echo "Không kết nối được Prometheus tại $PROM_URL. Đã chạy 'docker compose up -d' chưa?" >&2
    exit 1
  fi
}

# 0 = firing, 1 = khong firing, 2 = loi truy van.
# Tham so 2 la bo nhan bo sung, vi du: host="vm-web".

alert_firing() {
  local name="$1"
  local matchers="${2:-}"
  local selector="alertname=\"$name\",alertstate=\"firing\""
  local out

  if [[ -n "$matchers" ]]; then
    selector="$selector,$matchers"
  fi

  out="$(curl -fsS --get \
    --data-urlencode "query=ALERTS{$selector}" \
    "$PROM_URL/api/v1/query")" || return 2

  if [[ "$out" != *'"status":"success"'* ]]; then
    return 2
  fi

  if [[ "$out" == *'"result":[]'* ]]; then
    return 1
  fi

  return 0
}

# wait_for_alert <ten canh bao> [timeout] [start] [matchers]
wait_for_alert() {
  local name="$1"
  local timeout="${2:-300}"
  local start="${3:-$SECONDS}"
  local matchers="${4:-}"
  local result

  while (( SECONDS - start < timeout )); do
    if alert_firing "$name" "$matchers"; then
      log_event "DETECTED alert=$name detection_time=$((SECONDS - start))s"
      return 0
    else
      result=$?
    fi

    if (( result == 2 )); then
      echo "Loi truy van Prometheus khi kiem tra $name." >&2
    fi

    sleep 2
  done

  log_event "NOT_DETECTED alert=$name within ${timeout}s"
  return 1
}

# wait_for_resolved <ten canh bao> [timeout] [matchers]
wait_for_resolved() {
  local name="$1"
  local timeout="${2:-300}"
  local matchers="${3:-}"
  local start=$SECONDS
  local result

  while (( SECONDS - start < timeout )); do
    if alert_firing "$name" "$matchers"; then
      result=0
    else
      result=$?
    fi

    if (( result == 1 )); then
      log_event "RESOLVED alert=$name resolve_time=$((SECONDS - start))s"
      return 0
    elif (( result == 2 )); then
      echo "Loi truy van Prometheus khi kiem tra $name." >&2
    fi

    sleep 2
  done

  log_event "NOT_RESOLVED alert=$name within ${timeout}s"
  return 1
}
