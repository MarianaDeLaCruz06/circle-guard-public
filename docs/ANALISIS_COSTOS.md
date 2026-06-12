# Análisis de Costos de Infraestructura — CircleGuard

> Documento del **Requisito 9 — Documentación** del Proyecto Final IngeSoft V.
> Estimación, comparativa y estrategias de optimización de costos.

---

## 1. Resumen ejecutivo

Estimación mensual del costo total de operar CircleGuard en 3 ambientes (dev, stage, master) para una universidad mediana (~10.000 usuarios concurrentes pico, ~50 GB datos/mes):

| Modelo | Costo USD/mes | Costo USD/año |
|---|---:|---:|
| **Local (Docker Desktop, equipos del equipo)** | $0 | $0 |
| **GCP (GKE Autopilot, Cloud SQL, Memorystore)** | ~$680 | ~$8.160 |
| **AWS (EKS, RDS, ElastiCache)** | ~$720 | ~$8.640 |
| **Azure (AKS, Azure DB, Azure Cache)** | ~$700 | ~$8.400 |
| **GCP optimizado (preemptible + scale-to-zero stage)** | ~$390 | ~$4.680 |

> Decisión del proyecto: **modelo local-first** para defaults; los flujos cloud quedan documentados como opcionales en [`terraform.tfvars.gcp.example`](../terraform/environments/dev/terraform.tfvars.gcp.example).

---

## 2. Inventario de recursos

### 2.1 Recursos por ambiente (Terraform `terraform/environments/<env>/`)

| Recurso | dev (1 réplica) | stage (2 réplicas) | master (3 réplicas) |
|---|---|---|---|
| Microservicios CircleGuard | 6 deployments | 12 pods | 18 pods |
| PostgreSQL | 1 instancia | 1 instancia | 1 instancia HA |
| Neo4j | 1 instancia | 1 instancia | 1 instancia HA |
| Redis | 1 instancia | 1 instancia | 1 cluster (3 nodos) |
| Kafka + Zookeeper | 1 broker, 1 zk | 1 broker, 1 zk | 3 brokers, 3 zk |
| MinIO (Terraform state) | 1 instancia shared | shared | shared |
| Prometheus + Grafana | 1 stack shared | shared | shared |

### 2.2 Recursos por pod (resource requests/limits actuales)

| Servicio | CPU req/limit | Memory req/limit | Notas |
|---|---|---|---|
| Microservicios (cada uno) | 200m / 500m | 512Mi / 1Gi | Spring Boot baseline |
| Postgres | 250m / 1000m | 512Mi / 2Gi | + 20Gi PVC |
| Neo4j | 500m / 2000m | 1Gi / 4Gi | + 30Gi PVC |
| Redis | 100m / 500m | 256Mi / 1Gi | In-memory |
| Kafka | 500m / 2000m | 1Gi / 4Gi | + 50Gi PVC |
| Zookeeper | 100m / 500m | 256Mi / 1Gi | + 5Gi PVC |

---

## 3. Costos por proveedor (estimación mensual master + stage + dev)

> Precios en USD, región us-central1 (GCP) / us-east-1 (AWS) / eastus (Azure), tomados a junio 2026.

### 3.1 GCP — escenario base

| Componente | Tipo | Costo USD/mes |
|---|---|---:|
| GKE Autopilot cluster (3 nodos compartidos) | e2-standard-4 | $260 |
| Cloud SQL (PostgreSQL HA) | db-custom-2-7680 | $190 |
| Neo4j AuraDB Professional | 4 GB RAM | $65 |
| Memorystore Redis | 1 GB Basic Tier | $35 |
| Cloud Storage (backups + tfstate) | 50 GB | $1 |
| Load Balancer | 1 LB | $19 |
| Cloud Build / Container Registry | bajo uso | $15 |
| Network egress | 100 GB | $12 |
| Cloud Monitoring | 50 GB ingestion | $25 |
| Subtotal | | **$622** |
| **+ contingencia 10%** | | **$684** |

### 3.2 AWS — escenario base

| Componente | Tipo | Costo USD/mes |
|---|---|---:|
| EKS control plane | $73/mes flat | $73 |
| EC2 nodes (3 × t3.large) | 3 × $60.74 | $182 |
| RDS PostgreSQL Multi-AZ | db.t3.medium | $130 |
| Neo4j en EC2 (m5.large) | 1 × $69.84 | $70 |
| ElastiCache Redis | cache.t3.micro | $13 |
| MSK Kafka | 2 × kafka.t3.small | $103 |
| S3 (backups) | 50 GB | $1 |
| ALB | 1 LB | $18 |
| ECR | 50 GB | $5 |
| Data transfer out | 100 GB | $9 |
| CloudWatch | 50 GB | $50 |
| Subtotal | | **$654** |
| **+ contingencia 10%** | | **$720** |

### 3.3 Azure — escenario base

| Componente | Tipo | Costo USD/mes |
|---|---|---:|
| AKS (control plane gratuito) | — | $0 |
| VM nodes (3 × Standard_D2s_v3) | 3 × $70 | $210 |
| Azure DB PostgreSQL | GP_Gen5_2 | $145 |
| Azure Cosmos DB con API Gremlin (alternativa Neo4j) | 400 RU/s | $25 |
| Azure Cache for Redis | Basic C0 | $17 |
| Event Hubs (alternativa Kafka) | Standard 1 TU | $22 |
| Blob Storage | 50 GB | $1 |
| Load Balancer | Standard | $18 |
| Azure Container Registry | Basic | $5 |
| Application Insights | 50 GB | $115 |
| Subtotal | | **$558** |
| Contingencia 25% (Cosmos puede escalar más) | | **$697** |

---

## 4. Comparativa: features incluidas

| Feature | GCP | AWS | Azure | Local |
|---|:---:|:---:|:---:|:---:|
| Auto-scaling de nodos | ✅ Autopilot | ✅ Karpenter | ✅ AKS auto-scaler | ❌ |
| Backups automatizados de DB | ✅ | ✅ | ✅ | ❌ manual |
| Multi-AZ HA out of the box | ✅ | ✅ | ✅ | ❌ |
| TLS termination en LB | ✅ | ✅ | ✅ | ❌ |
| Neo4j managed | ✅ AuraDB | ❌ self-managed | ⚠️ Cosmos Gremlin (no es Neo4j) | ❌ |
| Kafka managed | ⚠️ no nativo | ✅ MSK | ⚠️ Event Hubs (proto distinto) | ❌ |
| Cost transparency | ✅ Recommender | ✅ Cost Explorer | ✅ Cost Management | ✅ trivial |
| Free tier para POCs | ✅ $300 trial | ✅ 12-mes free tier | ✅ $200 trial | N/A |

**Recomendación:** GCP gana en simplicidad de Neo4j managed (AuraDB) que es nuestro componente más crítico. AWS gana en Kafka managed (MSK). Azure es competitivo pero pierde compatibilidad nativa de Neo4j y Kafka.

---

## 5. Estrategias de optimización aplicadas

### 5.1 Local-first defaults (ahorro ~$8.000/año)

Los `terraform.tfvars` por defecto apuntan a `docker-desktop` con `NodePort`, no a GKE/EKS. Cualquier estudiante puede correr el sistema completo sin tarjeta de crédito.

### 5.2 Microservicios con resource limits estrictos

| Default Spring Boot | Optimizado CircleGuard |
|---|---|
| 2Gi heap por JVM | 512Mi req / 1Gi limit |
| Sin GC tuning | `-XX:+UseG1GC -XX:MaxGCPauseMillis=200` |
| 2 réplicas mínimo | 1 en dev, 2 en stage, 3 en prod |

Ahorro: ~40% menos de memoria reservada vs. defaults.

### 5.3 Cleanup automático en pipelines

`buildDiscarder(numToKeepStr: '5')` + `cleanupDockerImages()` en cada pipeline post.always: **previene los 92 GB acumulados** que observamos durante las primeras corridas (ver historia commit `561d2e8`).

### 5.4 Feature Toggles en runtime (sin redeploy)

Canales de notificación (email/sms/push) activables individualmente. Caso real: si Twilio falla, **apagar SMS sin tirar el sistema** ahorra costos de retries fallidos y mantiene la disponibilidad de otros canales.

### 5.5 Build Docker pre-compilado (commit `8bfd729`)

Refactor de Dockerfiles que dejó de recompilar el código en cada `docker build`:
- **Antes**: ~3 min × 8 imágenes × 5 pipelines/día = 2 horas/día de CI agent
- **Después**: ~10 seg × 8 × 5 = 7 min/día

A precio de agent CI = $0.04/min → **$50/mes ahorrados** solo en este refactor.

### 5.6 Cleanup de namespaces dev efímeros

Los pods en `circleguard-dev` se pueden tirar después de cada sprint:
```bash
cd terraform/environments/dev && terraform destroy
```
Ahorro: dev solo paga cuando se usa.

### 5.7 Estrategia preemptible/spot (no implementada, recomendada)

Para escenarios cloud:
- GCP: preemptible VMs = **70-80% más baratas** (interrupción ≤ 24h aceptable en dev/stage).
- AWS: Spot Instances = **hasta 90% más baratas** para workloads tolerantes a interrupción.

Estimación: aplicando preemptible a dev + stage en GCP, el costo bajaría de $684 a **~$390/mes** (43% ahorro).

---

## 6. Costo por unidad de funcionalidad

Métricas derivadas para conversaciones con stakeholders:

| Métrica | Cálculo | Valor (GCP base) |
|---|---|---|
| Costo por usuario/mes | $684 / 10.000 usuarios activos | $0.068 |
| Costo por check-in (gateway) | $684 / 3.000.000 check-ins | $0.00023 |
| Costo por notificación enviada | (twilio $0.0075 + infra $0.00005) | $0.00755 |
| Costo de operar 1 día | $684 / 30 | $22.80 |

---

## 7. Próximos análisis (no MVP)

- Implementar **GCP Recommender** o **AWS Trusted Advisor** para hallar oversizing automáticamente.
- Configurar **budgets + alertas** para cada ambiente.
- Adoptar **FinOps practices**: revisión mensual del informe, etiquetar todos los recursos con `cost-center: circleguard`.
- Evaluar migración a **Karpenter** (AWS) o **Cluster Autoscaler con consolidación agresiva** para optimizar nodos.
- Adoptar **Cloud Storage Nearline / S3 Glacier** para backups de DB con > 30 días.
