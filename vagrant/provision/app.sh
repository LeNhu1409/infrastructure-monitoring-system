#!/usr/bin/env bash
# vm-app: API Python rất nhỏ (chỉ dùng thư viện chuẩn) chạy như dịch vụ systemd, cổng 8000.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y python3
mkdir -p /opt/hkdn-api
cat > /opt/hkdn-api/app.py <<'PY'
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"status": "ok", "service": "hkdn-api"}).encode()
            self.send_response(200)
        elif self.path == "/":
            body = b"hkdn-api (vm-app) - HKDN N4.7 lab\n"
            self.send_response(200)
        else:
            body = b"not found\n"
            self.send_response(404)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
PY
cat > /etc/systemd/system/hkdn-api.service <<'UNIT'
[Unit]
Description=HKDN lab demo API
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/hkdn-api/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable hkdn-api
systemctl restart hkdn-api
