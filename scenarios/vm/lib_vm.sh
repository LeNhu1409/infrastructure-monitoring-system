#!/usr/bin/env bash
# Hàm dùng chung cho các kịch bản chạy trên máy ảo (Vagrant).

_VM_LIB_SOURCE="${BASH_SOURCE[0]}"
_VM_LIB_DIR="$(cd -- "$(dirname -- "$_VM_LIB_SOURCE")" && pwd)"

source "$_VM_LIB_DIR/../lib.sh"

REPO_DIR="$(cd -- "$_VM_LIB_DIR/../.." && pwd)"
VAGRANT_DIR="$REPO_DIR/vagrant"

# Chạy lệnh Vagrant thông qua Windows PowerShell.
vagrant_win() {
  local command="$1"
  local win_dir

  win_dir="$(wslpath -w "$VAGRANT_DIR")" || return 1

  powershell.exe -NoProfile -NonInteractive -Command \
    "Set-Location -LiteralPath '$win_dir'; & $command; if (\$LASTEXITCODE -ne 0) { exit \$LASTEXITCODE }"
}

# vm_ssh <tên VM> <lệnh>
vm_ssh() {
  local vm="$1"
  shift

  local remote_command="$*"
  local escaped_command

  escaped_command="${remote_command//\'/\'\'}"

  vagrant_win "vagrant ssh $vm -c '$escaped_command'"
}

require_vm() {
  local vm="$1"

  if ! vm_ssh "$vm" "true" >/dev/null 2>&1; then
    echo "Không kết nối được VM $vm qua Vagrant/SSH." >&2
    exit 1
  fi
}
