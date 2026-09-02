#!/usr/bin/env python3
"""
Project 50 Tracker — static server + save endpoint.

Start it:
    cd "/Users/idarlamo/Documents/Claude Code/Project 50 Tracker"
    python3 server.py

Then open http://localhost:8000 in your browser.
Leave this running while you use the dashboard. Ctrl+C to stop.

The dashboard's "Save" button POSTs to /save, which writes the new
current values into data.json and stamps todayDate with today's date.
"""

import datetime
import http.server
import json
import os
import pathlib
import socketserver

PORT = int(os.environ.get("PORT", "8000"))
ROOT = pathlib.Path(__file__).parent.resolve()
DATA = ROOT / "data.json"
EDITABLE = ("clientStarts", "abaHoursPerDay")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_POST(self):
        if self.path.rstrip("/") != "/save":
            self.send_error(404, "Unknown endpoint")
            return
        try:
            length = int(self.headers.get("Content-Length", 0))
            payload = json.loads(self.rfile.read(length) or b"{}")

            data = json.loads(DATA.read_text())
            for key in EDITABLE:
                value = payload.get(key)
                if value is None:
                    continue
                number = float(value)
                data[key]["current"] = int(number) if number.is_integer() else number
            data["todayDate"] = datetime.date.today().isoformat()

            DATA.write_text(json.dumps(data, indent=2) + "\n")
            self._send_json(200, data)
        except Exception as exc:  # noqa: BLE001 - report anything back to the page
            self._send_json(500, {"error": str(exc)})

    def _send_json(self, status, obj):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):
        print("  " + fmt % args)


class Server(socketserver.TCPServer):
    allow_reuse_address = True


with Server(("", PORT), Handler) as httpd:
    print(f"Project 50 Tracker  →  http://localhost:{PORT}")
    print("Ctrl+C to stop.\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
