# Observability

CircleGuard exposes a minimal Prometheus/Grafana observability baseline for the final project delivery.

## Scope

This phase covers:

- Spring Boot health checks through `/actuator/health`.
- Prometheus metrics through `/actuator/prometheus`.
- Prometheus scrape configuration for the eight CircleGuard services.
- A basic Grafana dashboard for service status, requests, latency, errors, and JVM memory.

This phase does not include ELK or Jaeger. Those remain next-step improvements.

## Instrumented services

All backend services include Spring Boot Actuator and the Prometheus Micrometer registry:

| Service | Port | Health | Metrics |
|---|---:|---|---|
| circleguard-auth-service | 8180 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-notification-service | 8082 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-identity-service | 8083 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-dashboard-service | 8084 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-file-service | 8085 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-form-service | 8086 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-gateway-service | 8087 | `/actuator/health` | `/actuator/prometheus` |
| circleguard-promotion-service | 8088 | `/actuator/health` | `/actuator/prometheus` |

## Local Prometheus

Prerequisites:

- Docker Desktop running.
- CircleGuard services running on the host ports listed above.

Run Prometheus:

```powershell
docker run --rm -p 9090:9090 `
  -v ${PWD}/observability/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml `
  prom/prometheus:v2.55.1
```

Open:

```text
http://localhost:9090/targets
```

Save a screenshot to:

```text
evidence/05-observability/prometheus-targets.png
```

## Local Grafana

Run Grafana:

```powershell
docker run --rm -p 3000:3000 grafana/grafana:11.3.0
```

Open:

```text
http://localhost:3000
```

Default credentials are `admin/admin`.

Add Prometheus as a datasource:

```text
http://host.docker.internal:9090
```

Import dashboard:

```text
observability/grafana/dashboards/circleguard-overview.json
```

Save screenshots to:

```text
evidence/05-observability/grafana-dashboard.png
evidence/05-observability/grafana-datasource.png
```

## Health check evidence

Use PowerShell:

```powershell
Invoke-WebRequest http://localhost:8180/actuator/health | Select-Object -ExpandProperty Content
Invoke-WebRequest http://localhost:8084/actuator/prometheus | Select-Object -ExpandProperty Content
```

Suggested evidence files:

```powershell
Invoke-WebRequest http://localhost:8180/actuator/health | Select-Object -ExpandProperty Content > evidence/05-observability/auth-health.txt
Invoke-WebRequest http://localhost:8084/actuator/prometheus | Select-Object -ExpandProperty Content > evidence/05-observability/dashboard-prometheus.txt
```
