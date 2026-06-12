#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Despliega kube-prometheus-stack en el cluster Kubernetes apuntado por
# el kubeconfig activo. Idempotente: re-ejecutar actualiza la release.
# -----------------------------------------------------------------------------
set -euo pipefail

NAMESPACE="${NAMESPACE:-monitoring}"
RELEASE="${RELEASE:-kube-prometheus-stack}"
CHART_VERSION="${CHART_VERSION:-65.5.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_FILE="${SCRIPT_DIR}/helm/values-monitoring.yaml"
DASHBOARD_FILE="${SCRIPT_DIR}/grafana/dashboards/circleguard-overview.json"

command -v helm >/dev/null 2>&1 || { echo "helm no esta instalado. https://helm.sh/docs/intro/install/"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl no esta instalado."; exit 1; }

echo "==> Cluster activo: $(kubectl config current-context)"
echo "==> Namespace: ${NAMESPACE}"
echo "==> Release:   ${RELEASE} (chart ${CHART_VERSION})"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

# Provisiona el dashboard de CircleGuard como ConfigMap (Grafana lo carga al boot)
kubectl -n "${NAMESPACE}" create configmap circleguard-overview \
    --from-file="${DASHBOARD_FILE}" \
    --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "${RELEASE}" prometheus-community/kube-prometheus-stack \
    --namespace "${NAMESPACE}" \
    --version "${CHART_VERSION}" \
    --values "${VALUES_FILE}" \
    --wait --timeout 10m

echo
echo "Listo. Para acceder a Grafana:"
echo "    kubectl -n ${NAMESPACE} port-forward svc/${RELEASE}-grafana 3000:80"
echo "    open http://localhost:3000  (admin / prom-operator)"
echo
echo "Para Prometheus:"
echo "    kubectl -n ${NAMESPACE} port-forward svc/${RELEASE}-prometheus 9090:9090"
