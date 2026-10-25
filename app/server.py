import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class ApplicationHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"status": "ok"}).encode()
            content_type = "application/json"
            status = 200
        elif self.path == "/":
            body = json.dumps(
                {
                    "service": "personal-project",
                    "version": os.environ.get("APP_VERSION", "local"),
                }
            ).encode()
            content_type = "application/json"
            status = 200
        else:
            body = json.dumps({"error": "not found"}).encode()
            content_type = "application/json"
            status = 404

        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        print("%s - %s" % (self.address_string(), format % args))


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8000), ApplicationHandler)
    server.serve_forever()
