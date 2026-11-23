#!/usr/bin/env bash
set -euo pipefail
base_url="${1:-http://localhost:8000}"
curl -fsS "$base_url/" | grep -q "monitoring demo"
test "$(curl -sS -o /dev/null -w '%{http_code}' "$base_url/demo-error")" = 503
metrics="$(curl -fsS "$base_url/metrics")"
grep -q 'demo_http_requests_total{status="200"}' <<< "$metrics"
grep -q 'demo_http_requests_total{status="503"}' <<< "$metrics"
grep -q '^process_start_time_seconds ' <<< "$metrics"
