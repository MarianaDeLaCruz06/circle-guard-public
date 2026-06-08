# Observability — CircleGuard

> Documento del **Requisito 7 — Observabilidad** del Proyecto Final IngeSoft V.

Este directorio contiene la configuración de monitoreo del proyecto:

| Archivo | Para qué sirve |
|---|---|
| [`prometheus/prometheus.yml`](prometheus/prometheus.yml) | Scrape config local para los 8 microservicios cuando se ejecuta Prometheus directamente con `docker run` |
| [`grafana/dashboards/circleguard-overview.json`](grafana/dashboards/circleguard-overview.json) | Dashboard de Grafana con visión general (CPU, JVM, requests, latencia, errores) |
| [`helm/values-monitoring.yaml`](helm/values-monitoring.yaml) | Values del chart `kube-prometheus-stack` con las personalizaciones del proyecto |
| [`install-monitoring.sh`](install-monitoring.sh) · [`install-monitoring.ps1`](install-monitoring.ps1) | Scripts idempotentes para desplegar la stack completa en Kubernetes (igual que en la evidencia) |

---

## 1. Despliegue rápido (recomendado): stack completa en Kubernetes

El proyecto utiliza el chart oficial **kube-prometheus-stack** de Prometheus Community. Despliega Prometheus, Alertmanager, Grafana, Prometheus Operator, kube-state-metrics y node-exporter — todo configurado y conectado.

### Linux / macOS

```bash
./observability/install-monitoring.sh
```

### Windows

```powershell
./observability/install-monitoring.ps1
```

Cuando termine:

```bash
# Acceder a Grafana (admin / prom-operator por default)
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# → http://localhost:3000

# Acceder a Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# → http://localhost:9090
```

### Importar el dashboard de CircleGuard

En Grafana → **Dashboards → New → Import** → cargar [`grafana/dashboards/circleguard-overview.json`](grafana/dashboards/circleguard-overview.json).

---

## 2. Despliegue alternativo: Prometheus standalone (sin Kubernetes)

Útil cuando los services corren directamente en host (no en cluster):

```powershell
docker run --rm -p 9090:9090 `
  -v ${PWD}/observability/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml `
  prom/prometheus:v2.55.1
```

```powershell
docker run --rm -p 3000:3000 grafana/grafana:11.3.0
```

Esta es la opción documentada originalmente en [`docs/OBSERVABILITY.md`](../docs/OBSERVABILITY.md). Sirve para verificación rápida, pero pierde las métricas a nivel de cluster (pods, nodes, kube-state).

---

## 3. Limitaciones conocidas en Docker Desktop

Algunos targets de la stack aparecen `DOWN` cuando se despliega en Docker Desktop:

- `kube-controller-manager`, `kube-scheduler`, `kube-etcd`, `kube-proxy`: Docker Desktop no expone los endpoints internos del control plane igual que un cluster productivo.
- `node-exporter`: requiere paths del kernel Linux (`/proc`, `/sys`) que la VM de Docker Desktop maneja diferente; queda en `CrashLoopBackOff`.

Estas limitaciones están documentadas en [`../evidence/05-observability/observability-notes.txt`](../evidence/05-observability/observability-notes.txt). No afectan las métricas de los servicios de aplicación, que sí son scrapeados normalmente vía `/actuator/prometheus`.

---

## 4. Limpieza

```bash
helm -n monitoring uninstall kube-prometheus-stack
kubectl delete namespace monitoring
```
