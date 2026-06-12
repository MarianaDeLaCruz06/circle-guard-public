# Evidencia de Sprints y Metodologia Agil - CircleGuard

## Metodologia usada

CircleGuard uso un enfoque de **Scrum adaptado** para un proyecto academico de microservicios. La documentacion base de roles, ceremonias y Definition of Done se encuentra en `docs/METODOLOGIA_AGIL.md`.

La adaptacion consistio en trabajar con iteraciones cortas orientadas a entregables tecnicos verificables: compilacion, pruebas, despliegue Kubernetes, CI/CD, seguridad, observabilidad y documentacion final.

## Estrategia de branching

La estrategia documentada es GitFlow adaptado:

- `dev`: integracion diaria y despliegue al namespace `circleguard-dev`.
- `stage`: validacion previa a produccion en `circleguard-stage`.
- `master`: version productiva en `circleguard-master`.
- `feature/*` y `bugfix/*`: ramas temporales para historias o correcciones especificas.

Evidencias relacionadas:

- `Jenkinsfile.dev`
- `Jenkinsfile.stage`
- `Jenkinsfile.master`
- `jenkins/shared.groovy`
- `k8s/namespace.yaml`
- `evidence/03-kubernetes/namespaces.txt`

## Limitacion sobre tablero agil

No se encontro en el repositorio una exportacion versionada de Jira, Trello, GitHub Projects u otro tablero real. Por esa razon, esta evidencia queda documentada en el repositorio mediante este archivo y `docs/METODOLOGIA_AGIL.md`. Para una entrega productiva se recomienda anexar capturas o enlace real al tablero con historias, estados y fechas.

## Iteracion 1 - Fundacion tecnica y despliegue base

### Objetivo

Construir la base funcional y operativa del sistema CircleGuard: microservicios, aplicacion movil, build backend, manifiestos Kubernetes iniciales y pruebas unitarias principales.

### Historias de usuario

| Historia | Descripcion | Criterios de aceptacion |
|---|---|---|
| HU-01 Autenticacion y roles | Como usuario del sistema, quiero autenticarme y recibir permisos para acceder a funcionalidades protegidas. | Existen modelos de roles/permisos, controlador de login y pruebas unitarias de login/token. |
| HU-02 Motor de promocion de estado | Como equipo de salud, quiero actualizar estados sanitarios anonimos para activar contencion. | Existen servicios/controladores de promocion y pruebas de ciclo de vida de estados. |
| HU-03 Formularios de salud | Como usuario, quiero reportar sintomas mediante formulario para alimentar el sistema. | Existen endpoints/modelos de encuestas y pruebas de cuestionario/encuesta. |
| HU-04 Build reproducible | Como equipo DevOps, quiero compilar todos los servicios desde Gradle. | `./gradlew.bat bootJar` genera artefactos backend exitosamente. |
| HU-05 Despliegue Kubernetes base | Como equipo DevOps, quiero desplegar servicios e infraestructura en namespaces separados. | Existen manifiestos K8s y evidencia de namespaces/pods/servicios. |

### Actividades realizadas

- Implementacion de microservicios backend bajo `services/`.
- Implementacion de aplicacion movil bajo `mobile/`.
- Configuracion Gradle multi-modulo.
- Creacion de Dockerfiles por servicio.
- Creacion de manifiestos Kubernetes para namespaces, configuracion, infraestructura y servicios.
- Ejecucion de build y pruebas unitarias.

### Evidencias del repo

- `services/circleguard-auth-service/`
- `services/circleguard-promotion-service/`
- `services/circleguard-form-service/`
- `services/circleguard-notification-service/`
- `services/circleguard-identity-service/`
- `services/circleguard-gateway-service/`
- `services/circleguard-dashboard-service/`
- `services/circleguard-file-service/`
- `mobile/`
- `build.gradle.kts`
- `settings.gradle.kts`
- `docker-compose.dev.yml`
- `k8s/`
- `evidence/01-build/backend-bootjar.txt`
- `evidence/02-tests/backend-unit-tests.txt`
- `evidence/02-tests/mobile-unit-tests.txt`
- `evidence/03-kubernetes/namespaces.txt`
- `evidence/03-kubernetes/all-pods.txt`
- `evidence/03-kubernetes/all-services.txt`

### Resultado

La iteracion dejo una base ejecutable del sistema, con microservicios compilables, pruebas unitarias principales, aplicacion movil y manifiestos Kubernetes para ambientes separados.

### Retrospectiva

Aspectos positivos:

- La estructura monorepo facilito centralizar builds, pruebas y despliegues.
- Kubernetes permitio representar ambientes `dev`, `stage` y `master` de manera uniforme.
- Las evidencias en `evidence/` facilitaron demostrar avances tecnicos.

Aspectos a mejorar:

- Formalizar antes el tablero agil y guardar capturas/versiones en el repositorio.
- Separar desde el inicio evidencias de build, pruebas, seguridad y observabilidad.
- Evitar que configuraciones locales queden mezcladas con configuraciones esperadas para produccion.

## Iteracion 2 - DevOps, seguridad, observabilidad y documentacion final

### Objetivo

Fortalecer el cumplimiento del proyecto final con CI/CD avanzado, Terraform, pruebas completas, seguridad, observabilidad, release notes y documentacion academica.

### Historias de usuario

| Historia | Descripcion | Criterios de aceptacion |
|---|---|---|
| HU-06 Pipelines por ambiente | Como equipo DevOps, quiero pipelines separados para dev, stage y master. | Existen `Jenkinsfile.dev`, `Jenkinsfile.stage` y `Jenkinsfile.master`. |
| HU-07 Infraestructura como codigo | Como equipo DevOps, quiero definir infraestructura con Terraform modular. | Existen modulos Terraform, ambientes `dev/stage/prod` y backend remoto documentado. |
| HU-08 Pruebas completas | Como equipo QA, quiero unitarias, integracion, E2E, rendimiento y seguridad. | Existen docs, scripts y evidencias en `docs/PRUEBAS_COMPLETAS.md`, `e2e/`, `performance/locust/`, `security/` y `evidence/`. |
| HU-09 Observabilidad base | Como operador, quiero monitorear salud y metricas tecnicas. | Existen configuraciones Prometheus/Grafana y evidencias en `evidence/05-observability/`. |
| HU-10 Release final documentada | Como equipo de entrega, quiero release notes y documentacion final. | Existen `release-notes.md`, `evidence/06-release/release-notes.md` y documentos en `docs/`. |

### Actividades realizadas

- Creacion de pipelines Jenkins por ambiente.
- Extraccion de logica compartida en `jenkins/shared.groovy`.
- Configuracion de SonarQube mediante `sonar-project.properties`.
- Integracion de Trivy y OWASP ZAP como controles de seguridad.
- Definicion de Terraform modular con ambientes `dev`, `stage` y `prod`.
- Creacion de dashboard Grafana y configuracion Prometheus.
- Ejecucion/documentacion de Locust y ZAP.
- Generacion de release notes.

### Evidencias del repo

- `Jenkinsfile.dev`
- `Jenkinsfile.stage`
- `Jenkinsfile.master`
- `jenkins/shared.groovy`
- `jenkins/jobs/circleguard-dev.xml`
- `jenkins/jobs/circleguard-stage.xml`
- `jenkins/jobs/circleguard-master.xml`
- `sonar-project.properties`
- `terraform/README.md`
- `terraform/modules/`
- `terraform/environments/dev/`
- `terraform/environments/stage/`
- `terraform/environments/prod/`
- `terraform/global/backend-bootstrap/`
- `terraform/diagrams/architecture.mermaid`
- `docs/CICD_AVANZADO.md`
- `docs/PRUEBAS_COMPLETAS.md`
- `docs/OBSERVABILITY.md`
- `docs/PATRONES_DE_DISENO.md`
- `e2e/circleguard-e2e.postman_collection.json`
- `performance/locust/locustfile.py`
- `performance/locust/report.html`
- `security/`
- `evidence/04-security/zap-baseline-report.html`
- `evidence/04-security/trivy-notes.txt`
- `evidence/05-observability/`
- `release-notes.md`
- `evidence/06-release/release-notes.md`

### Resultado

La iteracion amplio el cumplimiento DevOps del proyecto: IaC con Terraform, CI/CD por ambiente, pruebas de multiples niveles, seguridad basica, observabilidad base y documentacion del proyecto final.

### Retrospectiva

Aspectos positivos:

- La separacion de pipelines por ambiente ayudo a representar promocion controlada.
- Terraform cubrio modularidad, ambientes y backend remoto.
- Las carpetas `evidence/`, `security/`, `performance/` y `observability/` dejaron trazabilidad de validaciones.

Aspectos a mejorar:

- SonarQube y Trivy requieren evidencia de ejecucion completa y no solo configuracion.
- ELK, Jaeger/Zipkin, TLS productivo y RBAC Kubernetes no estan implementados y deben quedar como recomendaciones.
- Las limitaciones de Docker Desktop afectaron algunos targets de Prometheus y node-exporter.

## Backlog resumido

| Item | Prioridad | Estado |
|---|---|---|
| Exportar tablero real de gestion agil | Alta | Pendiente |
| Agregar evidencia de SonarQube ejecutado | Alta | Pendiente |
| Integrar Trivy completamente sin limitaciones locales | Alta | Parcial |
| Implementar TLS real para servicios expuestos | Alta | Pendiente |
| Implementar RBAC Kubernetes | Alta | Pendiente |
| Agregar ELK Stack | Media | Pendiente |
| Agregar Jaeger o Zipkin | Media | Pendiente |
| Crear dashboards Grafana por microservicio | Media | Pendiente |
| Documentar costos cloud estimados | Media | Cubierto en `docs/COSTOS.md` |
| Documentar runbook operativo | Media | Cubierto en `docs/OPERACIONES.md` |
