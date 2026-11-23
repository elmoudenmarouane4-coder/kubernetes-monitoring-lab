#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
namespace=monitoring-lab

docker build -t monitoring-demo:local .
minikube image load monitoring-demo:local --overwrite=true
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

config() {
  kubectl -n "$namespace" create configmap "$@" --dry-run=client -o yaml | kubectl -n "$namespace" apply -f -
}

config prometheus-config --from-file=prometheus.yml --from-file=alerts.yml
config grafana-datasource --from-file=grafana/datasource.yml
config grafana-provider --from-file=grafana/provider.yml
config grafana-dashboard --from-file=grafana/dashboard.json
kubectl -n "$namespace" apply -f kubernetes/workloads.yaml
kubectl -n "$namespace" rollout restart deployment/demo-api deployment/prometheus deployment/grafana
kubectl -n "$namespace" rollout status deployment/demo-api --timeout=180s
kubectl -n "$namespace" rollout status deployment/prometheus --timeout=180s
kubectl -n "$namespace" rollout status deployment/grafana --timeout=180s
