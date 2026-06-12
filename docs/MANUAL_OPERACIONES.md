# Manual de Operaciones — CircleGuard

> Documento del **Requisito 9 — Documentación** del Proyecto Final IngeSoft V.
> Guía operativa para arrancar, operar, diagnosticar y mantener el sistema CircleGuard.

---

## 1. Bootstrap del sistema (de cero a corriendo)

### Prerrequisitos en la máquina del operador

| Herramienta | Versión mínima | Verificación |
|---|---|---|
| Docker Desktop | 4.30+ | `docker --version` |
| Kubernetes habilitado en Docker Desktop | 1.31+ | `kubectl version --client` |
| Java | 21 LTS | `java -version` |
| Terraform | 1.6.0+ | `terraform version` |
| Helm | 3.14+ | `helm version` (solo para observabilidad) |
| Git | 2.40+ | `git --version` |

### 1.1 Clonar y configurar

```bash
git clone https://github.com/MarianaDeLaCruz06/circle-guard-public.git
cd circle-guard-public
```

### 1.2 Levantar middleware local (rápido — para desarrollo individual)

```bash
docker-compose -f docker-compose.dev.yml up -d
```

Esto arranca: PostgreSQL, Neo4j, Kafka, Zookeeper, Redis y OpenLDAP.

### 1.3 Compilar y arrancar todos los microservicios

```bash
./gradlew bootJar
./gradlew bootRun --parallel
```

O un servicio específico:
```bash
./gradlew :services:circleguard-auth-service:bootRun
```

### 1.4 Bootstrap completo en Kubernetes (recomendado para integración)

Paso 1 — backend remoto de Terraform (MinIO):
```bash
cd terraform/global/backend-bootstrap
terraform init
terraform apply -auto-approve
```

Paso 2 — exportar credenciales:
```powershell
$env:AWS_ACCESS_KEY_ID = "minioadmin"
$env:AWS_SECRET_ACCESS_KEY = "minioadmin123"
```

Paso 3 — desplegar ambiente:
```bash
cd ../../environments/dev    # o stage / prod
terraform init
terraform apply -auto-approve
```

Paso 4 — observabilidad:
```bash
./observability/install-monitoring.sh
```

Paso 5 — verificar:
```bash
kubectl get pods -A
kubectl -n circleguard-dev get svc
```

---

## 2. Operaciones de rutina

### 2.1 Ver el estado del sistema

```bash
# Pods de un ambiente
kubectl -n circleguard-master get pods

# Logs en tiempo real de un servicio
kubectl -n circleguard-master logs -f deployment/circleguard-auth-service

# Métricas de un servicio (require port-forward)
kubectl -n circleguard-master port-forward svc/circleguard-auth-service 8180:8180
curl http://localhost:8180/actuator/health | jq
curl http://localhost:8180/actuator/prometheus
```

### 2.2 Dashboards de Grafana

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# Abrir http://localhost:3000  (admin / prom-operator)
```

Dashboard preconfigurado: **CircleGuard / CircleGuard Overview**.

### 2.3 Ejecutar un cambio (deploy)

Ver flujo completo en [`CHANGE_MANAGEMENT.md`](CHANGE_MANAGEMENT.md). Resumen:

1. Crear rama `feature/<id>` desde `develop`.
2. Push → abrir PR a `develop`.
3. Pipeline `circle-guard-dev` se dispara automáticamente.
4. Tras review + merge → pipeline `circle-guard-stage`.
5. Aprobar manualmente el stage `Approval to Deploy Production` en `circle-guard-master`.

### 2.4 Rollback de un servicio

```bash
./scripts/rollback-k8s.sh circleguard-master circleguard-auth-service
```

Ver escenarios adicionales en [`ROLLBACK_PLAYBOOK.md`](ROLLBACK_PLAYBOOK.md).

### 2.5 Cambiar un feature toggle sin redeploy

```bash
# Apagar SMS instantáneamente
kubectl -n circleguard-master set env deployment/circleguard-notification-service \
  CIRCLEGUARD_FEATURES_SMS_ENABLED=false
```

### 2.6 Backup de bases de datos

```bash
# PostgreSQL
POD=$(kubectl -n circleguard-master get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl -n circleguard-master exec -it $POD -- pg_dumpall -U admin > backup-pg-$(date +%F).sql

# Neo4j (cypher-shell)
POD=$(kubectl -n circleguard-master get pod -l app=neo4j -o jsonpath='{.items[0].metadata.name}')
kubectl -n circleguard-master exec -it $POD -- neo4j-admin database dump neo4j --to-path=/tmp
kubectl -n circleguard-master cp $POD:/tmp/neo4j.dump ./backup-neo4j-$(date +%F).dump
```

Frecuencia recomendada: diaria a S3 / MinIO.

---

## 3. Troubleshooting

### 3.1 "Pod en CrashLoopBackOff"

```bash
# 1. Ver evento detallado
kubectl -n circleguard-master describe pod <pod-name>

# 2. Ver logs de la última crashed instance
kubectl -n circleguard-master logs <pod-name> --previous

# 3. Causas comunes:
#    - DB todavía no levantada → esperar liveness probe
#    - Bad config (ConfigMap mal) → ver "Environment" en describe
#    - Image pull error → verificar tag/registry credentials
```

### 3.2 "Circuit Breaker quedó OPEN y no cierra"

Síntoma: `/actuator/health` muestra `circuitBreakers.identityService.state: OPEN`.

```bash
# Verificar el servicio downstream
kubectl -n circleguard-master get pod -l app=circleguard-identity-service

# Si el downstream está OK, esperar wait_duration (10s default) — Resilience4j
# transiciona automáticamente a HALF_OPEN y prueba con tráfico limitado.

# Si necesitas forzar el reset, basta reiniciar el pod del upstream:
kubectl -n circleguard-master rollout restart deployment/circleguard-auth-service
```

### 3.3 "Kafka no consume mensajes"

```bash
# 1. Ver consumer groups
POD=$(kubectl -n circleguard-master get pod -l app=kafka -o jsonpath='{.items[0].metadata.name}')
kubectl -n circleguard-master exec -it $POD -- kafka-consumer-groups \
  --bootstrap-server localhost:9092 --list

# 2. Ver lag de un grupo
kubectl -n circleguard-master exec -it $POD -- kafka-consumer-groups \
  --bootstrap-server localhost:9092 --group notification-group --describe

# 3. Si hay lag alto, escalar el consumer:
kubectl -n circleguard-master scale deployment/circleguard-notification-service --replicas=3
```

### 3.4 "Trivy bloquea el master pipeline"

Síntoma: stage `Trivy Container Scan` falla con `Trivy encontro vulnerabilidades HIGH/CRITICAL`.

```bash
# Ejecutar trivy localmente para ver el detalle
trivy image --severity HIGH,CRITICAL circleguard-auth-service:<tag>

# Opciones:
# A) Actualizar la base image en el Dockerfile (preferido)
# B) Si es falso positivo: agregarlo a .trivyignore con justificación
# C) Si urge un hotfix: usar pipeline de Emergency (ver CHANGE_MANAGEMENT.md)
```

### 3.5 "El disco se llena"

Causa común: builds Docker acumulados, workspace de Jenkins.

```powershell
# Inspeccionar Docker
docker system df

# Limpieza segura
docker system prune -af --filter="until=24h"

# Si es WSL2 vhdx que creció (Windows):
# 1. wsl --shutdown
# 2. Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx"
```

### 3.6 "No puedo entrar a Jenkins (olvidé la clave)"

Ver el procedimiento en sesiones anteriores: usar init.groovy.d para resetear:

```bash
docker exec jenkins mkdir -p /var/jenkins_home/init.groovy.d
cat > reset.groovy <<'EOF'
import jenkins.model.*
import hudson.security.*
def user = hudson.model.User.getById('admin', false)
user.addProperty(HudsonPrivateSecurityRealm.Details.fromPlainPassword('NEW_PASSWORD'))
user.save()
EOF
docker cp reset.groovy jenkins:/var/jenkins_home/init.groovy.d/
docker restart jenkins
# Después de login, borrar el script:
docker exec jenkins rm /var/jenkins_home/init.groovy.d/reset.groovy
```

---

## 4. On-call procedures

### 4.1 Severidad de incidentes

| Severidad | Definición | Tiempo respuesta | Quién responde |
|---|---|---|---|
| **P0** | Servicio totalmente caído / fuga de datos confirmada | 15 min | On-call + DevOps Lead + PO |
| **P1** | Funcionalidad crítica degradada (gateway, auth) | 1 h | On-call + DevOps Lead |
| **P2** | Funcionalidad no crítica degradada | 4 h | On-call |
| **P3** | Bug menor / mejora | siguiente sprint | Backlog |

### 4.2 Runbook de incidente P0

1. **Acknowledge**: marcar el alert en Grafana / Slack en < 5 min.
2. **Comunicar**: postear en `#circleguard-incidents` con estado inicial.
3. **Mitigar**: ejecutar rollback (ver Sección 2.4) **antes** de investigar la causa raíz.
4. **Investigar**: revisar logs, métricas, recent commits.
5. **Resolver**: forward fix o rollback definitivo.
6. **Post-mortem**: 48h después, sin culpar, documentar causa raíz + plan de prevención.

### 4.3 Contactos del equipo

| Rol | Persona | Slack | Email |
|---|---|---|---|
| Product Owner | Valentina | @valentina | po@circleguard.example |
| Scrum Master | Mariana | @mariana | sm@circleguard.example |
| DevOps Lead | Alexis | @alexis | devops@circleguard.example |

---

## 5. Mantenimiento programado

### 5.1 Mensual
- Rotar credenciales de DB y secrets de Kafka.
- Verificar coverage > 70% en SonarQube.
- Auditar accesos a Jenkins.

### 5.2 Trimestral
- Actualizar dependencias (`./gradlew dependencyUpdates`).
- Revisar y limpiar feature toggles obsoletos.
- Probar el plan de rollback con un drill (game day).

### 5.3 Anual
- Renovar certificados TLS.
- Auditoría externa de seguridad (penetration test).
- Revisión arquitectónica completa.

---

## 6. Cheat sheet de comandos

```bash
# === Build & test ===
./gradlew bootJar                                # Compilar todos
./gradlew test                                   # Tests unitarios
./gradlew integrationTest                        # Tests integración
./gradlew jacocoTestReport                       # Coverage HTML

# === Docker ===
docker-compose -f docker-compose.dev.yml up -d   # Middleware local
docker system prune -af                          # Limpiar imágenes

# === Kubernetes ===
kubectl get pods -A                              # Estado global
kubectl -n circleguard-master logs -f deploy/<svc>  # Logs en vivo
kubectl -n circleguard-master rollout undo deploy/<svc>  # Rollback rápido

# === Terraform ===
cd terraform/environments/dev
terraform plan
terraform apply

# === Observabilidad ===
./observability/install-monitoring.sh
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# === Seguridad ===
./security/zap-scan.sh                           # ZAP baseline
trivy image circleguard-auth-service:1.2.3      # Trivy ad-hoc

# === Pruebas E2E y carga ===
newman run e2e/circleguard-e2e.postman_collection.json
locust -f performance/locust/locustfile.py --headless -u 100 -r 10 -t 5m
```
