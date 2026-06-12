# -----------------------------------------------------------------------------
# Rollback rápido de un Deployment en Kubernetes.
# Acompañado por docs/ROLLBACK_PLAYBOOK.md sección 3.
#
# Uso:
#   ./scripts/rollback-k8s.ps1 -Namespace <ns> -Deployment <deploy> [-Revision <n>]
#
# Ejemplos:
#   ./scripts/rollback-k8s.ps1 -Namespace circleguard-master -Deployment circleguard-auth-service
#   ./scripts/rollback-k8s.ps1 -Namespace circleguard-stage  -Deployment circleguard-promotion-service -Revision 7
# -----------------------------------------------------------------------------
param(
    [Parameter(Mandatory=$true)][string]$Namespace,
    [Parameter(Mandatory=$true)][string]$Deployment,
    [int]$Revision = 0
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl no está instalado."
}

Write-Host "==> Cluster activo: $(kubectl config current-context)"
Write-Host "==> Namespace:      $Namespace"
Write-Host "==> Deployment:     $Deployment"
Write-Host ""
Write-Host "==> Historial actual:"
kubectl -n $Namespace rollout history "deployment/$Deployment"

Write-Host ""
$ans = Read-Host "¿Confirmas el rollback? [yes/N]"
if ($ans -ne 'yes') {
    Write-Host "Cancelado."
    exit 0
}

Write-Host ""
Write-Host "==> Ejecutando rollback..."
if ($Revision -gt 0) {
    kubectl -n $Namespace rollout undo "deployment/$Deployment" "--to-revision=$Revision"
} else {
    kubectl -n $Namespace rollout undo "deployment/$Deployment"
}

Write-Host ""
Write-Host "==> Esperando que el rollback complete..."
kubectl -n $Namespace rollout status "deployment/$Deployment" --timeout=180s

Write-Host ""
Write-Host "==> Estado final:"
kubectl -n $Namespace get pods -l "app=$Deployment"

Write-Host ""
Write-Host "Rollback completo. Ejecuta los smoke tests post-rollback (ver ROLLBACK_PLAYBOOK.md sección 9)."
