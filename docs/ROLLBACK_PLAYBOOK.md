# Rollback Playbook — CircleGuard

> Documento complementario al [`CHANGE_MANAGEMENT.md`](CHANGE_MANAGEMENT.md) — describe procedimientos concretos para revertir cambios en cada capa del sistema.

---

## 1. Cuándo ejecutar un rollback

Dispara este playbook si después de un despliegue ocurre alguno de los siguientes:

| Síntoma | Severidad | Detección |
|---|---|---|
| Tasa de errores HTTP > 5% durante 5 min | 🔴 Crítica | Dashboard Grafana `circleguard-overview` |
| Latencia p95 > 2x del baseline durante 5 min | 🔴 Crítica | Métrica `http_server_requests_seconds` en Prometheus |
| Healthcheck `/actuator/health` reporta DOWN en cualquier servicio | 🔴 Crítica | Smoke Tests del pipeline + alerta Prometheus |
| Circuit Breaker en estado `OPEN` por > 5 min | 🟡 Alta | `/actuator/health` → `circuitBreakers` |
| Fuga de información o vulnerabilidad detectada | 🔴 Crítica | OWASP ZAP en producción / report manual |
| Datos corruptos en PostgreSQL o Neo4j | 🔴 Crítica | Alertas de integridad / queries de validación |

> **Regla de oro**: rollback primero, debug después. Restaurar el servicio tiene prioridad sobre entender por qué falló.

---

## 2. Decisión rápida: ¿qué rollback necesito?

```
                  ┌──────────────────────────────────────┐
                  │ ¿Qué cambió en el despliegue actual? │
                  └─────────────────┬────────────────────┘
                                    │
       ┌────────────────────────────┼──────────────────────────┐
       ▼                            ▼                          ▼
 Solo código de un             Configuración              Schema de DB
 microservicio                 (ConfigMap/Secret)         (migración)
       │                            │                          │
       ▼                            ▼                          ▼
 Sección 3                    Sección 4                  Sección 5
 (kubectl rollout)            (kubectl rollback)         (Flyway repair + manual)
       │                            │                          │
       ▼                            ▼                          ▼
 Cambió infraestructura       Falla en múltiples           Incidente de seguridad
 (k8s/, terraform/)           servicios                    (CVE, ZAP HIGH)
       │                            │                          │
       ▼                            ▼                          ▼
 Sección 6                    Sección 7                  Sección 8
 (terraform apply previa)     (cluster-wide rollback)    (parche emergencia)
```

---

## 3. Rollback de un microservicio (caso más común)

**Cuándo:** un único servicio empezó a fallar después del despliegue.

**Tiempo estimado:** 1–2 minutos.

### Procedimiento

```bash
# 1. Identificar el deployment afectado (ejemplo: auth)
kubectl -n circleguard-master rollout history deployment/circleguard-auth-service

# 2. Hacer rollback a la revisión anterior
kubectl -n circleguard-master rollout undo deployment/circleguard-auth-service

# 3. Verificar que el rollback completó
kubectl -n circleguard-master rollout status deployment/circleguard-auth-service --timeout=180s

# 4. Smoke test
curl -sS http://localhost:8180/actuator/health | jq
```

Para automatizar los 4 pasos arriba, usar el script:

```bash
# Linux/macOS
./scripts/rollback-k8s.sh circleguard-master circleguard-auth-service

# Windows
./scripts/rollback-k8s.ps1 circleguard-master circleguard-auth-service
```

---

## 4. Rollback de ConfigMap o Secret

**Cuándo:** se cambió un valor de configuración (toggle de feature, URL externa, secret) y eso provocó errores.

**Tiempo estimado:** < 1 minuto (la app no se reinicia si el valor se inyecta vía env).

### Procedimiento

```bash
# 1. Encontrar el ConfigMap que cambió
kubectl -n circleguard-master get configmap circleguard-config -o yaml > /tmp/current.yaml

# 2. Identificar el commit que introdujo el cambio
git log --oneline -- k8s/config.yaml

# 3. Restaurar la versión anterior
git checkout <SHA-ANTERIOR> -- k8s/config.yaml
kubectl -n circleguard-master apply -f k8s/config.yaml

# 4. Forzar restart de los pods que dependan del ConfigMap (si el cambio no es hot-reload)
kubectl -n circleguard-master rollout restart deployment
```

Para **Feature Toggles** específicamente, el rollback es aún más simple porque son env vars:

```bash
# Apagar canal SMS sin reiniciar
kubectl -n circleguard-master set env deployment/circleguard-notification-service \
  CIRCLEGUARD_FEATURES_SMS_ENABLED=false
```

---

## 5. Rollback de migración de DB (Flyway)

**Cuándo:** una migración SQL rompió un servicio.

**Tiempo estimado:** 5–15 minutos (puede requerir intervención manual).

⚠️ **Las migraciones de DB NO son reversibles automáticamente.** Flyway no provee `migrate down`. Hay 3 estrategias:

### Estrategia A — Forward Fix (preferida)

Si la migración fue aditiva (agregó columna/tabla):

```sql
-- Crear una nueva migración V<N+1>__rollback_<descripcion>.sql que revierta
-- (DROP COLUMN, DROP TABLE, UPDATE valores, etc.)
```

Subir el fix por el pipeline normal.

### Estrategia B — Snapshot Restore

Si los datos quedaron corruptos:

```bash
# 1. Identificar el último backup válido (ver runbook DB)
# 2. Aislar el servicio
kubectl -n circleguard-master scale deployment/circleguard-auth-service --replicas=0

# 3. Restaurar el snapshot
psql -h <host> -U <user> circleguard_auth < /backups/latest-pre-deploy.sql

# 4. Marcar la migración como ignorada
psql -c "DELETE FROM flyway_schema_history WHERE version = '<X.Y>';"

# 5. Re-escalar
kubectl -n circleguard-master scale deployment/circleguard-auth-service --replicas=1
```

### Estrategia C — flyway repair

Si la migración falló a la mitad y `flyway_schema_history` quedó inconsistente:

```bash
./gradlew :services:circleguard-auth-service:flywayRepair
```

---

## 6. Rollback de infraestructura (Terraform)

**Cuándo:** un `terraform apply` rompió el cluster o desconfiguró servicios.

**Tiempo estimado:** 5–10 minutos.

### Procedimiento

```bash
cd terraform/environments/master   # o el ambiente afectado

# 1. Identificar el commit anterior estable
git log --oneline -- terraform/

# 2. Checkout solo de los archivos terraform
git checkout <SHA-ANTERIOR> -- terraform/

# 3. Plan + apply en seco para ver qué se va a revertir
terraform plan -out=rollback.tfplan

# 4. Si el plan es razonable, aplicarlo
terraform apply rollback.tfplan

# 5. Verificar que el cluster respondió bien
kubectl get pods -n circleguard-master
```

> **Nota**: el tfstate vive en MinIO ([`terraform/global/backend-bootstrap/`](../terraform/global/backend-bootstrap/)) — Terraform automáticamente reconcilia contra el estado deseado. No es necesario manipular el tfstate manualmente.

---

## 7. Rollback de release completo (cluster-wide)

**Cuándo:** múltiples servicios fallan tras un release `vX.Y.Z`.

**Tiempo estimado:** 10–15 minutos.

### Procedimiento

```bash
# 1. Identificar el tag anterior
git tag --sort=-v:refname | head -5

# 2. Lanzar el pipeline master sobre el tag anterior
#    (en la UI de Jenkins: Build with Parameters → seleccionar Git Ref = vX.Y.Z-1)
#    Esto re-construye y re-despliega la versión anterior.

# 3. Alternativa rápida: re-tag las imágenes ya construidas a :latest
for s in auth identity form promotion notification gateway dashboard file; do
  docker tag circleguard-${s}-service:<X.Y.Z-1> circleguard-${s}-service:current
done

# 4. Actualizar todos los Deployments al tag anterior
for s in auth identity form promotion notification gateway dashboard file; do
  kubectl -n circleguard-master set image deployment/circleguard-${s}-service \
    circleguard-${s}-service=circleguard-${s}-service:<X.Y.Z-1>
done

# 5. Esperar a que todos los rollouts completen
kubectl -n circleguard-master rollout status deployment --timeout=300s
```

---

## 8. Rollback de emergencia por seguridad

**Cuándo:** Trivy o ZAP detectan una vulnerabilidad HIGH/CRITICAL después de un release ya productivo, o se reporta un incidente de seguridad activo.

**Tiempo estimado:** 5 minutos.

### Procedimiento

```bash
# 1. Pausar el gateway para detener el tráfico entrante
kubectl -n circleguard-master scale deployment/circleguard-gateway-service --replicas=0

# 2. Si el bug es localizable a un servicio: rollback Sección 3
# 3. Si es transversal: rollback Sección 7

# 4. Activar Feature Toggles defensivos
kubectl -n circleguard-master set env deployment/circleguard-notification-service \
  CIRCLEGUARD_FEATURES_EMAIL_ENABLED=false \
  CIRCLEGUARD_FEATURES_SMS_ENABLED=false

# 5. Re-escalar el gateway al terminar el rollback
kubectl -n circleguard-master scale deployment/circleguard-gateway-service --replicas=1

# 6. Verificar con ZAP
./security/zap-scan.sh http://localhost:8087
```

⚠️ **Obligatorio post-rollback de emergencia:** post-mortem en 48h con timeline, root cause y plan de prevención.

---

## 9. Validación post-rollback

Después de cualquier rollback, ejecutar esta checklist:

- [ ] Todos los pods `Running` en el namespace afectado:
      `kubectl get pods -n circleguard-master`
- [ ] `/actuator/health` reporta `UP` en todos los servicios.
- [ ] Smoke Tests del pipeline pasan:
      ejecutar `Jenkinsfile.master` solo hasta el stage `Smoke Tests`.
- [ ] Métricas Grafana volvieron al baseline (latencia + error rate).
- [ ] No hay Circuit Breakers en estado `OPEN`.
- [ ] Crear un issue para el forward fix (si aplica).

---

## 10. Métricas de rollback

| KPI | Objetivo | Cómo se mide |
|---|---|---|
| **MTTR (Mean Time To Recover)** | < 15 min | Desde el detect del problema hasta el smoke test verde post-rollback. |
| **Frecuencia de rollbacks** | < 10% de los despliegues | Sumar tags de release vs ejecuciones de este playbook. |
| **% rollbacks exitosos al primer intento** | > 90% | Sin necesidad de escalar a Estrategia B o C de Sección 5. |
