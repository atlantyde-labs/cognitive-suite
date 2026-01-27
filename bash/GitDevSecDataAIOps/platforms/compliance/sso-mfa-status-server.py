#!/usr/bin/env python3
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = os.environ.get("LISTEN_ADDR", "0.0.0.0")
PORT = int(os.environ.get("LISTEN_PORT", "8999"))
SSO_ENABLED = os.environ.get("SSO_ENABLED", "false").lower() == "true"
MFA_ENFORCED = os.environ.get("MFA_ENFORCED", "false").lower() == "true"

class Handler(BaseHTTPRequestHandler):
    def _send(self, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/sso":
            self._send({"sso_enabled": SSO_ENABLED, "enabled": SSO_ENABLED})
            return
        if self.path == "/mfa":
            self._send({"mfa_enforced": MFA_ENFORCED, "enabled": MFA_ENFORCED})
            return
        self.send_response(404)
        self.end_headers()

    def log_message(self, fmt, *args):
        return

if __name__ == "__main__":
    httpd = HTTPServer((HOST, PORT), Handler)
    print(f"SSO/MFA status server on {HOST}:{PORT}")
    httpd.serve_forever()
