# -----------------------------------------------------------------------------
# Despliega kube-prometheus-stack en el cluster Kubernetes apuntado por
# el kubeconfig activo. Idempotente: re-ejecutar actualiza la release.
# -----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

$namespace      = if ($env:NAMESPACE)      { $env:NAMESPACE }      else { 'monitoring' }
$release        = if ($env:RELEASE)        { $env:RELEASE }        else { 'kube-prometheus-stack' }
$chartVersion   = if ($env:CHART_VERSION)  { $env:CHART_VERSION }  else { '65.5.0' }

$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$valuesFile    = Join-Path $scriptDir 'helm/values-monitoring.yaml'
$dashboardFile = Join-Path $scriptDir 'grafana/dashboards/circleguard-overview.json'

if (-not (Get-Command helm -ErrorAction SilentlyContinue))    { throw "helm no esta instalado. https://helm.sh/docs/intro/install/" }
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw "kubectl no esta instalado." }

Write-Host "==> Cluster activo: $(kubectl config current-context)"
Write-Host "==> Namespace: $namespace"
Write-Host "==> Release:   $release (chart $chartVersion)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null | Out-Null
helm repo update | Out-Null

kubectl get namespace $namespace 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { kubectl create namespace $namespace }

# Provisiona el dashboard de CircleGuard como ConfigMap
kubectl -n $namespace create configmap circleguard-overview `
    --from-file=$dashboardFile `
    --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install $release prometheus-community/kube-prometheus-stack `
    --namespace $namespace `
    --version $chartVersion `
    --values $valuesFile `
    --wait --timeout 10m

Write-Host ""
Write-Host "Listo. Para acceder a Grafana:"
Write-Host "    kubectl -n $namespace port-forward svc/$release-grafana 3000:80"
Write-Host "    Open http://localhost:3000  (admin / prom-operator)"
Write-Host ""
Write-Host "Para Prometheus:"
Write-Host "    kubectl -n $namespace port-forward svc/$release-prometheus 9090:9090"
