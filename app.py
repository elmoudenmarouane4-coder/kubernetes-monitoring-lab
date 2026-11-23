from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from time import perf_counter

from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

REQUESTS = Counter("demo_http_requests_total", "Demo HTTP requests", ["status"])
LATENCY = Histogram("demo_http_request_duration_seconds", "Demo response time")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            self.respond(200, CONTENT_TYPE_LATEST, generate_latest())
            return
        if self.path == "/healthz":
            self.respond(200, "text/plain", b"ok\n")
            return

        start = perf_counter()
        status, body = {
            "/": (200, b"monitoring demo\n"),
            "/demo-error": (503, b"simulated service error\n"),
        }.get(self.path, (404, b"not found\n"))
        self.respond(status, "text/plain", body)
        REQUESTS.labels(status=str(status)).inc()
        LATENCY.observe(perf_counter() - start)

    def respond(self, status, content_type, body):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
