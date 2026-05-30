# Terraform — Infraestructura como Codigo de CircleGuard

Este directorio implementa el **Requisito 2** del Proyecto Final IngeSoft V:

> Configurar toda la infraestructura necesaria usando Terraform
> con estructura modular, multiples ambientes y backend remoto.

## Arquitectura

```
terraform/
+-- versions.tf                 # Providers globales (kubernetes, helm)
+-- README.md                   # Este archivo
+-- diagrams/                   # Diagramas de arquitectura
+-- global/
|   +-- backend-bootstrap/      # Despliega MinIO como backend S3 remoto
+-- modules/                    # Modulos reutilizables
|   +-- namespace/              # Namespace + ConfigMap + Secret compartidos
|   +-- postgres/               # PostgreSQL 16 + init DBs
|   +-- neo4j/                  # Neo4j 5.26 + APOC
|   +-- kafka/                  # Kafka 7.6 + Zookeeper
|   +-- redis/                  # Redis 7.2
|   +-- microservice/           # Modulo generico para los 6 servicios CircleGuard
|   +-- circleguard-stack/      # Compone toda la stack (namespace + infra + servicios)
+-- environments/
    +-- dev/                    # 1 replica, recursos bajos, namespace circleguard-dev
    +-- stage/                  # 2 replicas, recursos medios, namespace circleguard-stage
    +-- prod/                   # 3 replicas, recursos altos, namespace circleguard-master
```

## Decisiones de diseno

| Decision | Razon |
|---|---|
| **Provider: Kubernetes local** (Docker Desktop / Minikube) | Sin costos cloud; alineado al stack actual del proyecto |
| **Backend remoto: MinIO en K8s** | S3-compatible 100% gratis; cumple el requisito de backend remoto sin depender de un cloud |
| **Modulo `circleguard-stack`** | Evita duplicacion entre ambientes; cada ambiente solo pasa replicas y recursos |
| **Namespaces por ambiente** | `circleguard-dev`, `circleguard-stage`, `circleguard-master` (alineados con los Jenkinsfiles) |
| **Mismas imagenes** (`:local`) | Las construye CI/CD; el tag se puede sobreescribir via `-var image_tag=...` |

## Prerequisitos

- Terraform >= 1.5
- Kubernetes local: **Docker Desktop con Kubernetes habilitado** o **Minikube**
- `kubectl` configurado (`kubectl get nodes` debe responder)
- Imagenes Docker de los servicios construidas localmente (ver `Jenkinsfile.dev`):
  ```bash
  ./gradlew bootJar
  for s in auth identity form promotion notification gateway; do
    docker build -f services/circleguard-$s-service/Dockerfile -t circleguard-$s-service:local .
  done
  ```

## Despliegue end-to-end

### Paso 1 — Bootstrap del backend remoto

```bash
cd terraform/global/backend-bootstrap
terraform init
terraform apply
```

Esto despliega MinIO en el namespace `terraform-backend` y crea el bucket
`terraform-state`. La consola queda disponible en `http://localhost:30901`.

### Paso 2 — Exportar credenciales del backend

**PowerShell:**
```powershell
$env:AWS_ACCESS_KEY_ID = "minioadmin"
$env:AWS_SECRET_ACCESS_KEY = "minioadmin123"
```

**Bash:**
```bash
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin123
```

### Paso 3 — Aplicar un ambiente

```bash
cd terraform/environments/dev    # o stage / prod
terraform init
terraform plan
terraform apply
```

Cada ambiente guarda su estado en `s3://terraform-state/<env>/terraform.tfstate`.

### Paso 4 — Verificar

```bash
kubectl get pods -n circleguard-dev
kubectl get svc -n circleguard-dev
terraform output services
```

## Diferencias entre ambientes

| Aspecto | dev | stage | prod |
|---|---|---|---|
| Namespace | `circleguard-dev` | `circleguard-stage` | `circleguard-master` |
| Replicas (servicios) | 1 | 2 | 3 |
| CPU request | 100m | 200m | 500m |
| Memory request | 256Mi | 512Mi | 1Gi |
| Backend key | `dev/terraform.tfstate` | `stage/terraform.tfstate` | `prod/terraform.tfstate` |

## Variables principales por ambiente

| Variable | Default dev | Default stage | Default prod | Descripcion |
|---|---|---|---|---|
| `namespace` | `circleguard-dev` | `circleguard-stage` | `circleguard-master` | Namespace de K8s |
| `image_tag` | `local` | `local` | `local` | Tag de las imagenes de servicios |
| `replicas` | 1 | 2 | 3 | Replicas por microservicio |
| `kubeconfig_context` | `docker-desktop` | `docker-desktop` | `docker-desktop` | Contexto kube |

Sobreescribir desde la linea de comandos:
```bash
terraform apply -var image_tag=1.2.3 -var replicas=2
```

## Destruir

```bash
cd terraform/environments/dev
terraform destroy
```

Y para limpiar MinIO:
```bash
cd terraform/global/backend-bootstrap
terraform destroy
```

## Mapeo con los YAML originales (`k8s/`)

| YAML original | Modulo Terraform equivalente |
|---|---|
| `k8s/namespace.yaml` | `modules/namespace` (genera el namespace por env) |
| `k8s/config.yaml` (ConfigMap + Secret) | `modules/namespace` (config_data, secret_data) |
| `k8s/infrastructure.yaml` (Postgres, Neo4j, Kafka, Zookeeper, Redis) | `modules/postgres`, `modules/neo4j`, `modules/kafka`, `modules/redis` |
| `k8s/services.yaml` (6 microservicios) | `modules/microservice` x6, orquestados por `modules/circleguard-stack` |

Los YAMLs originales se conservan como referencia historica. El estado real de la
infraestructura se gestiona desde Terraform.

## Diagrama

Ver `diagrams/architecture.mermaid`.
