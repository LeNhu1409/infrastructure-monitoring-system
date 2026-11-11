#!/usr/bin/env bash
# Hàm dùng chung cho kịch bản chạy trên máy ảo (Vagrant).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

VAGRANT_DIR="$(cd "$SCENARIO_DIR/../vagrant" && pwd)"

# vm_ssh <tên vm> <lệnh...>: chạy lệnh trong VM.
vm_ssh() {
  local vm="$1"; shift
  ( cd "$VAGRANT_DIR" && vagrant ssh "$vm" -c "$*" ) 
}

require_vm() {
  local vm="$1"
  if ! vm_ssh "$vm" "true" >/dev/null 2>&1; then
    echo "Không vào được VM $vm. Đã chạy 'cd vagrant && vagrant up' chưa?" >&2
    exit 1
  fi
}
