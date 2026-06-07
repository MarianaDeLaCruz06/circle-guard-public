# Manual de Operaciones Basico - CircleGuard

## Objetivo

Proveer una guia operativa minima para compilar, probar, revisar despliegues, abrir herramientas de observabilidad, ejecutar seguridad basica y realizar rollback del sistema CircleGuard.

## Requisitos

- Docker Desktop.
- Kubernetes habilitado en Docker Desktop o cluster compatible.
- Java 21.
- Gradle Wrapper incluido en el repositorio.
- `kubectl`.
- Docker CLI.
- Git.
- Node.js y npm para pruebas mobile/E2E si aplica.

## Compilar backend

Desde la raiz del repositorio:

```powershell
.\gradlew.bat bootJar
```

Evidencia relacionada:

- `evidence/01-build/backend-bootjar.txt`

## Ejecutar pruebas backend

```powershell
.\gradlew.bat test
```

Evidencias relacionadas:

- `evidence/02-tests/backend-unit-tests.txt`
- `evidence/02-tests/notification-service-test.txt`

## Ejecutar pruebas mobile

```powershell
cd mobile
npm test
```

Evidencia relacionada:

- `evidence/02-tests/mobile-unit-tests.txt`

## Revisar Kubernetes

Ver todos los pods:

```powershell
kubectl get pods -A
```

Ver todos los servicios:

```powershell
kubectl get svc -A
```

Ver namespaces esperados:

```powershell
kubectl get namespaces
```

Evidencias relacionadas:

- `evidence/03-kubernetes/namespaces.txt`
- `evidence/03-kubernetes/all-pods.txt`
- `evidence/03-kubernetes/all-services.txt`

## Abrir Prometheus

Port-forward:

```powershell
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Abrir en navegador:

```text
http://localhost:9090
```

Evidencias relacionadas:

- `evidence/05-observability/prometheus-targets.png`
- `observability/prometheus/prometheus.yml`

## Abrir Grafana

Port-forward:

```powershell
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Abrir en navegador:

```text
http://localhost:3000
```

Dashboard del repositorio:

- `observability/grafana/dashboards/circleguard-overview.json`

Evidencias relacionadas:

- `evidence/05-observability/grafana-home.png`
- `evidence/05-observability/grafana-datasource.png`
- `evidence/05-observability/grafana-dashboard.png`

## Ejecutar OWASP ZAP

Linux/macOS:

```bash
./security/zap-scan.sh
```

Windows:

```powershell
.\security\zap-scan.bat
```

Baseline PowerShell:

```powershell
.\security\zap\zap-baseline.ps1
```

Con target especifico:

```powershell
.\security\zap\zap-baseline.ps1 -TargetUrl "http://host.docker.internal:8180"
```

Evidencia relacionada:

- `evidence/04-security/zap-baseline-report.html`

## Ejecutar Trivy con Docker

En Windows, usando Docker y montando el repositorio:

```powershell
docker run --rm -v "${PWD}:/project" aquasec/trivy:latest fs --severity HIGH,CRITICAL --no-progress /project
```

Si se desea guardar evidencia:

```powershell
docker run --rm -v "${PWD}:/project" aquasec/trivy:latest fs --severity HIGH,CRITICAL --no-progress /project *> evidence/04-security/trivy-fs-scan.txt
```

Evidencias relacionadas:

- `evidence/04-security/trivy-fs-scan.txt`
- `evidence/04-security/trivy-notes.txt`

## Ejecutar pruebas de rendimiento con Locust

```powershell
locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --host http://localhost:8180 --html performance/locust/report.html
```

Evidencias relacionadas:

- `performance/locust/README.md`
- `performance/locust/report.html`

## Rollback operativo

Rollback de un deployment:

```powershell
kubectl rollout undo deployment/<deployment-name> -n <namespace>
```

Ejemplo:

```powershell
kubectl rollout undo deployment/circleguard-auth-service -n circleguard-master
```

Verificar estado:

```powershell
kubectl rollout status deployment/<deployment-name> -n <namespace>
kubectl get pods -n <namespace>
```

Namespaces de referencia:

- `circleguard-dev`
- `circleguard-stage`
- `circleguard-master`

## Troubleshooting

### Prometheus targets DOWN en Docker Desktop

En Docker Desktop Kubernetes algunos endpoints internos del control plane no se exponen igual que en un cluster productivo. Esto puede generar targets `DOWN` aunque Prometheus y Grafana esten funcionando.

Evidencia y nota:

- `evidence/05-observability/observability-notes.txt`

### node-exporter en CrashLoopBackOff

En Windows con Docker Desktop, node-exporter puede fallar por restricciones de mounts del host Linux virtualizado, por ejemplo `/proc`, `/sys` o root filesystem.

Evidencia:

- `evidence/05-observability/node-exporter-describe.txt`

### LDAP health DOWN

En ejecuciones locales, el health check LDAP puede aparecer `DOWN` si OpenLDAP no esta levantado. Revisar `docker-compose.dev.yml` y levantar dependencias locales cuando se requiera validar autenticacion completa.

Comando de referencia:

```powershell
docker-compose -f docker-compose.dev.yml up -d
```

### Trivy en Git Bash con paths de Windows

El montaje de rutas con espacios o formato Windows puede fallar al ejecutar Trivy desde Git Bash. Preferir PowerShell con `${PWD}` o documentar la limitacion en `evidence/04-security/trivy-notes.txt`.

### kubectl sin contexto activo

Si Jenkins o la terminal local no tienen contexto Kubernetes activo:

```powershell
kubectl config current-context
kubectl get nodes
```

En Docker Desktop, validar que Kubernetes este habilitado y que el contexto sea `docker-desktop`.
