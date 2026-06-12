# Costos de Infraestructura - CircleGuard

## Alcance

El entorno usado para la entrega academica de CircleGuard esta basado principalmente en ejecucion local con Docker Desktop, Kubernetes local, Jenkins local/configurado y herramientas open source. Por tanto, **no genera costos cloud reales** mientras se ejecute en la maquina local del equipo.

Evidencias de enfoque local:

- `terraform/README.md`
- `docker-compose.dev.yml`
- `k8s/`
- `observability/`
- `evidence/03-kubernetes/`

## Costos reales del entorno academico

| Recurso | Costo directo cloud | Observacion |
|---|---:|---|
| Docker Desktop local | 0 USD | Uso academico/local. |
| Kubernetes local | 0 USD | Ejecutado en Docker Desktop. |
| PostgreSQL local/contenedor | 0 USD | Incluido en manifiestos o compose. |
| Neo4j local/contenedor | 0 USD | Sin servicio administrado cloud. |
| Redis local/contenedor | 0 USD | Sin servicio administrado cloud. |
| Kafka local/contenedor | 0 USD | Sin servicio administrado cloud. |
| Prometheus/Grafana local | 0 USD | Stack open source. |
| Jenkins local | 0 USD | Sin costo de SaaS. |

## Estimacion para una version cloud

La siguiente tabla es una estimacion conceptual para una version cloud pequena. Los valores exactos dependen del proveedor, region, trafico, politicas de alta disponibilidad, almacenamiento y licenciamiento.

| Componente | Opcion cloud tipica | Estimacion mensual academica/minima | Consideraciones |
|---|---|---:|---|
| Kubernetes cluster | GKE, AKS, EKS o cluster gestionado | 70-250 USD | Puede incluir costo de control plane y nodos worker. |
| Nodos de computo | 2-3 VMs pequenas | 60-180 USD | Dev/stage pueden usar nodos pequenos o apagarse fuera de horario. |
| PostgreSQL | Servicio administrado o contenedor en cluster | 25-150 USD | Produccion deberia usar backups y alta disponibilidad. |
| Neo4j | VM/contenedor o servicio administrado | 30-200 USD | El costo puede subir por memoria y almacenamiento. |
| Redis | Servicio administrado o contenedor | 15-80 USD | Cache pequena para validacion QR y sesiones. |
| Kafka | Servicio administrado o despliegue propio | 80-400 USD | Kafka administrado suele ser costoso; para academia conviene reducir alcance. |
| Storage | Buckets y volumenes persistentes | 5-50 USD | Incluye archivos, certificados, reportes y backups. |
| Monitoring | Prometheus/Grafana o servicio cloud | 0-100 USD | Open source reduce costo, pero requiere operacion. |
| CI/CD | Jenkins propio o SaaS | 0-100 USD | Jenkins propio consume VM; SaaS depende de minutos. |
| Trafico/red | Load balancer e ingress | 10-80 USD | TLS y exposicion publica agregan costo. |

## Recomendaciones FinOps

- Apagar ambientes `dev` y `stage` cuando no se usen.
- Mantener recursos minimos en `dev` y `stage`.
- Separar `prod` de entornos academicos para evitar pruebas costosas.
- Usar autoscaling solo donde tenga sentido y con limites definidos.
- Definir requests/limits por microservicio antes de pasar a cloud.
- Monitorear costos por namespace, ambiente o etiqueta.
- Evitar Kafka administrado en una primera version cloud si el presupuesto es limitado.
- Usar almacenamiento con politicas de retencion para evidencias, logs y backups.
- Configurar alertas de presupuesto en el proveedor cloud.
- Revisar periodicamente recursos huerfanos: volumenes, load balancers, imagenes y snapshots.

## Relacion con Terraform

La infraestructura actual esta definida en `terraform/` con:

- Modulos reutilizables en `terraform/modules/`.
- Ambientes separados en `terraform/environments/dev`, `terraform/environments/stage` y `terraform/environments/prod`.
- Backend remoto S3-compatible con MinIO en `terraform/global/backend-bootstrap/`.

Para una version cloud, Terraform deberia extenderse con:

- Variables de region y proveedor.
- Etiquetas de costo por ambiente.
- Politicas de retencion de volumenes.
- Presupuestos y alertas cloud si el proveedor lo permite.
- Separacion de secretos mediante un gestor externo.

## Conclusion

El proyecto cumple el enfoque academico sin costos cloud reales porque usa infraestructura local y herramientas open source. Para una version productiva, el mayor costo probable estaria en Kubernetes, Kafka, bases de datos administradas y monitoreo. La recomendacion es iniciar con una arquitectura cloud minima, medir uso real y escalar gradualmente.
