#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Rollback rápido de un Deployment en Kubernetes.
# Acompañado por docs/ROLLBACK_PLAYBOOK.md sección 3.
#
# Uso:
#   ./scripts/rollback-k8s.sh <namespace> <deployment> [revision]
#
# Ejemplos:
#   ./scripts/rollback-k8s.sh circleguard-master circleguard-auth-service
#   ./scripts/rollback-k8s.sh circleguard-stage  circleguard-promotion-service 7
# -----------------------------------------------------------------------------
set -euo pipefail

if [[ $# -lt 2 ]]; then
    cat <<EOF
ERROR: argumentos insuficientes.

Uso: $0 <namespace> <deployment> [revision]

Sin [revision] hace rollback a la revisión inmediatamente anterior (kubectl rollout undo).
Con [revision] hace rollback a esa revisión específica (verifica con: kubectl rollout history).
EOF
    exit 1
fi

NAMESPACE="$1"
DEPLOYMENT="$2"
REVISION="${3:-}"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl no está instalado."; exit 1; }

echo "==> Cluster activo: $(kubectl config current-context)"
echo "==> Namespace:      ${NAMESPACE}"
echo "==> Deployment:     ${DEPLOYMENT}"

echo
echo "==> Historial actual:"
kubectl -n "${NAMESPACE}" rollout history "deployment/${DEPLOYMENT}"

echo
read -rp "¿Confirmas el rollback? [yes/N] " ans
if [[ "${ans:-}" != "yes" ]]; then
    echo "Cancelado."
    exit 0
fi

echo
echo "==> Ejecutando rollback..."
if [[ -n "${REVISION}" ]]; then
    kubectl -n "${NAMESPACE}" rollout undo "deployment/${DEPLOYMENT}" --to-revision="${REVISION}"
else
    kubectl -n "${NAMESPACE}" rollout undo "deployment/${DEPLOYMENT}"
fi

echo
echo "==> Esperando que el rollback complete..."
kubectl -n "${NAMESPACE}" rollout status "deployment/${DEPLOYMENT}" --timeout=180s

echo
echo "==> Estado final:"
kubectl -n "${NAMESPACE}" get pods -l app="${DEPLOYMENT}"

echo
echo "Rollback completo. Ejecuta los smoke tests post-rollback (ver ROLLBACK_PLAYBOOK.md sección 9)."
