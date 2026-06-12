# 🛡️ CircleGuard Monorepo

### Developers
- **Mariana De La Cruz**
- **Valentina Gómez**
- **Alexis Delgado**

### Video
[![Circle-Guard-Video-Youtube](https://www.youtube.com/watch?v=LA23jlWIMEE)](https://youtube.com)

**Absolute Privacy. High-Speed Containment. Secure Campus.**

CircleGuard is a state-of-the-art university contact tracing and fencing system designed to identify interconnected contact groups ("Circles") and apply rapid health fences while preserving individual anonymity.

---

## 🌟 Vision & Mission

Our vision is a university campus where health containment speed outpaces lab confirmation timelines without compromising student privacy. CircleGuard leverages campus-native intelligence—class schedules and WiFi infrastructure—to deliver a human-validated, graph-based protection ecosystem.

### Key Differentiators
- **Privacy-as-Code**: Zero real-name exposure outside a secure Health Center vault.
- **Recursive Containment**: Status promotion cascades (Suspect → Probable → Confirmed) that trigger in milliseconds.
- **Campus Integration**: Smart check-ins using existing WiFi AP triangulation and Bluetooth Low Energy (BLE).

---

## 📊 Success Metrics

| Metric | Target | Measurement |
|:---|:---|:---|
| **Containment Speed** | < 60 Seconds | Automated test of promotion engine cascade |
| **Privacy Compliance** | 100% Anonymity | Penetration test on graph database (Zero real names) |
| **Check-in Adoption** | > 70% | Analytics on scheduled class contact validation |
| **False Positive Rate** | < 15% | Post-fence surveys of actual vs. suspected contact |
| **System Uptime** | 99.5% | 7:00 AM – 10:00 PM (Academic Peak Hours) |

---

## 🏗️ Architecture Overview

CircleGuard follows a **Microservice Architecture** built on a **Hybrid Data Model**.

### Core Engine
1. **Status Promotion Machine**: Uses **Neo4j** for recursive graph traversals to identify contacts within a 14-day temporal window.
2. **Anonymization Vault**: A segregated **PostgreSQL** vault handles salted-hash identity mapping, compliant with **FERPA** regulations.
3. **Event-Driven Core**: **Apache Kafka** manages asynchronous status changes, audit logs, and notification dispatches.

### Services Directory
- **Auth Service**: Dual-chain LDAP (University) / Local (Guest) auth with Dynamic RBAC.
- **Identity Service**: Cryptographic vault for anonymizing real identities.
- **Promotion Service**: The status engine (Recursive Graph Processing).
- **Notification Service**: Multi-channel dispatcher (Push/Email/SMS).
- **Form Service**: Dynamic health questionnaire engine.
- **Gateway Service**: Campus entry validation via signed, time-limited QR tokens.
- **Dashboard Service**: Geospatial hotspot analytics (Privacy-preserving).
- **File Service**: Secure certificate and document storage (S3-compatible).

---

## 🛠️ Technical Stack

| Layer | Technology | Rationale |
|:---|:---|:---|
| **Backend** | Spring Boot 4 / Java 21 | Enterprise-grade maturity & low-latency Jakarta EE support. |
| **Graph DB** | Neo4j 5.26 | High-performance recursive traversals unreachable with SQL. |
| **Relational DB**| PostgreSQL 16 | ACID compliant storage for identity and configuration. |
| **Message Bus** | Apache Kafka 7.6 | Persistent, audit-trailed event log for status dispatches. |
| **Caching** | Redis 7.2 | L2 distributed cache for rapid entry-gate status validation. |
| **Mobile/Web** | Expo (React Native) | Unified codebase across iOS, Android, and Browser. |
| **Infra** | Kubernetes | Orchestration for high availability and auto-scaling. |

---

## 🗺️ Roadmap

### Phase 1: MVP — The Intelligence Core (Current)
- [x] Status Promotion Machine (Suspect → Probable → Confirmed).
- [x] Temporal graph with 14-day TTL edges.
- [x] Multi-channel fence notifications (Push/Email/SMS).
- [ ] Health Center de-identification console.

### Phase 2: Growth — Spatial Intelligence
- [ ] WiFi AP triangulation integration.
- [ ] Campus entry validation (Gatekeeper) QR integration.
- [ ] LMS integration for "Remote Attendance" status automation.

### Phase 3: Vision — Full Ecosystem
- [ ] Off-campus circle detection via P2P Bluetooth.
- [ ] Global Health Dashboard with hotspot visualization.
- [ ] Lab API bridge for automated test result ingestion.

---

## 💻 Local Development

### 1. Infrastructure
Ensure Docker is installed, then start the middleware stack:
```bash
docker-compose -f docker-compose.dev.yml up -d
```
*Middleware includes: PostgreSQL, Neo4j, Kafka, Zookeeper, Redis, and OpenLDAP.*

### 2. Build & Run
CircleGuard uses Gradle for parallel builds across services:
```bash
# Start all microservices in parallel
./gradlew bootRun --parallel

# Start a specific service
./gradlew :services:<service-name>:bootRun
```

### 3. API Exploration
Every service exposes an OpenAPI 3.0 interface. Once running, visit:
`http://localhost:<service-port>/swagger-ui/index.html`

---

## 📱 Frontend Development

The frontend is built using **Expo (React Native)**, supporting iOS, Android, and Web from a single codebase located in `/mobile`.

### 1. Prerequisites
Ensure you have Node.js installed and dependencies loaded:
```bash
cd mobile
npm install
```

### 2. Run the Application
You can run the app in various modes depending on your target platform:

| Platform | Command | Notes |
|:---|:---|:---|
| **Development Menu** | `npm run start` | Opens the Expo Go start-up menu. |
| **Android** | `npm run android` | Requires Android Studio / Emulator or a connected device. |
| **iOS** | `npm run ios` | Requires macOS with Xcode / Simulator installed. |
| **Web Browser** | `npm run web` | Launches the dashboard/app in your default browser. |

### 3. Testing
To run frontend unit and component tests:
```bash
npm run test
```

---

## 🧪 Testing

We maintain high system integrity via multi-level testing:

| Command | Scope |
|:---|:---|
| `./gradlew test` | Full system suite (Unit + Integration) |
| `./gradlew :services:<name>:test` | Single service testing |

**Note**: Integration tests use **Testcontainers** to spawn ephemeral Neo4j and PostgreSQL instances for zero-side-effect validation.

---

## 🔐 Privacy & Compliance

- **FERPA Compliance**: Student identities are never stored in the contact graph.
- **Right to be Forgotten**: Users can trigger complete data purging via the Identity Vault.
- **Temporal Privacy**: All contact edges are automatically purged after 14 days.

---

## 🎓 Proyecto Final IngeSoft V

Esta sección rastrea el cumplimiento de los requisitos del **Proyecto Final de Ingeniería de Software V** y enlaza a los documentos y artefactos de cada uno.

| # | Requisito | Peso | Estado | Documentación |
|:---:|:---|:---:|:---:|:---|
| 1 | Metodología Ágil y Branching | 10% | ✅ | [`docs/METODOLOGIA_AGIL.md`](docs/METODOLOGIA_AGIL.md) |
| 2 | Infraestructura como Código (Terraform) | 20% | ✅ | [`terraform/README.md`](terraform/README.md) · [diagrama](terraform/diagrams/architecture.mermaid) |
| 3 | Patrones de Diseño | 10% | ✅ | [`docs/PATRONES_DE_DISENO.md`](docs/PATRONES_DE_DISENO.md) |
| 4 | CI/CD Avanzado | 15% | ✅ | [`docs/CICD_AVANZADO.md`](docs/CICD_AVANZADO.md) · [`Jenkinsfile.dev`](Jenkinsfile.dev) · [`Jenkinsfile.stage`](Jenkinsfile.stage) · [`Jenkinsfile.master`](Jenkinsfile.master) · [`jenkins/shared.groovy`](jenkins/shared.groovy) |
| 5 | Pruebas Completas | 15% | ✅ | [`docs/PRUEBAS_COMPLETAS.md`](docs/PRUEBAS_COMPLETAS.md) · JaCoCo [`build.gradle.kts`](build.gradle.kts) · OWASP ZAP [`security/README.md`](security/README.md) · E2E [`e2e/`](e2e/) · Locust [`performance/locust/`](performance/locust/) |
| 6 | Change Management & Release Notes | 5% | ⚠️ parcial | Release Notes automáticas en `Jenkinsfile.master`; falta proceso formal de rollback |
| 7 | Observabilidad | 10% | ❌ | Pendiente: Prometheus + Grafana, ELK, Jaeger |
| 8 | Seguridad | 5% | ❌ | Pendiente: TLS, secrets management, OWASP ZAP |
| 9 | Documentación | 10% | ⚠️ parcial | Este README + docs por requisito; pendiente guías de operación formales |

### Resumen de los requisitos completos

**Req. 2 — Terraform (20%)** — Estructura modular en [`terraform/`](terraform/) con 7 módulos reutilizables, 3 ambientes (dev/stage/prod) y backend remoto S3-compatible vía MinIO en Kubernetes. Defaults locales (Docker Desktop) para reproducibilidad sin cloud; flujo GKE documentado como opcional.

**Req. 3 — Patrones de Diseño (10%)** — Catálogo de 8 patrones preexistentes (Repository, Chain of Responsibility, Strategy+Dispatcher, Observer/Event-Driven, DTO, Filter Chain, Converter, API Gateway) con referencias archivo:línea, más 3 patrones nuevos implementados con Resilience4j 2.2.0:
- **Circuit Breaker** en `IdentityClient` (auth→identity) y `PromotionClient` (dashboard→promotion) con fallbacks degradados.
- **Retry con backoff exponencial** componiendo con el Circuit Breaker.
- **Feature Toggle** vía `@ConfigurationProperties` para canales de notificación (email/sms/push), cambiable sin redeploy.

**Req. 4 — CI/CD Avanzado (15%)** — 3 pipelines Jenkins (dev/stage/master) con:
- **SonarQube** análisis estático multi-módulo.
- **Trivy** escaneo de contenedores (advisory en dev/stage, **gate HIGH/CRITICAL en master**).
- **Versionado semántico automático** por canal (`0.0.0-dev.<sha>`, `<tag>-rc.<n>`, `X.Y.Z+1`).
- **Notificaciones de fallo** vía email con fallback.
- **Aprobación manual a producción** con timeout 60 min y submitters restringidos.
- **Cleanup automático** (`buildDiscarder`, `cleanupDockerImages`, `cleanupWorkspace`) para mantener el agente bajo control de disco.

**Req. 6 — Change Management y Release Notes (5%)** — Proceso formal documentado:
- **Clasificación de cambios** (Standard / Normal / Emergency) con criterios, aprobación y ventana.
- **Matriz RACI** explícita (PO, SM, Dev/DevOps Lead, CAB).
- **Plantilla de Change Request** para PRs y issues.
- **Release Notes automáticas** generadas por `Jenkinsfile.master` y archivadas como artifact.
- **Tag git semántico** (`vX.Y.Z`) publicado opcionalmente con `CREATE_GIT_TAG=true`.
- **Playbook de rollback** con 7 escenarios concretos (microservicio, ConfigMap, DB, Terraform, release completo, emergencia de seguridad) + scripts `rollback-k8s.{sh,ps1}` ejecutables.

**Req. 9 — Documentación (10%)** — Documentación operativa y arquitectónica completa:
- [`ARQUITECTURA.md`](docs/ARQUITECTURA.md) — vista de alto nivel + diagramas Mermaid de componentes, flujos críticos (entrada al campus, promoción event-driven, resiliencia con CB) y topología K8s. Stack tecnológico justificado + 7 ADRs.
- [`MANUAL_OPERACIONES.md`](docs/MANUAL_OPERACIONES.md) — runbook: bootstrap from-scratch, operaciones de rutina (deploys, rollbacks, feature toggles, backups), troubleshooting de 6 incidentes comunes, on-call procedures con severidades y cheat sheet.
- [`ANALISIS_COSTOS.md`](docs/ANALISIS_COSTOS.md) — estimación por componente para GCP/AWS/Azure (~$680/mes), comparativa, estrategias de optimización aplicadas y costo por unidad de funcionalidad.
- [`ANALISIS_PRUEBAS.md`](docs/ANALISIS_PRUEBAS.md) — coverage por servicio (73% promedio), benchmark Locust (20.5 req/s, 0 fallos), hallazgos ZAP (0 HIGH), Trivy (0 HIGH/CRITICAL en master), SonarQube Quality Gate PASS y lecciones aprendidas.

Pendientes humanos: grabar el video demostrativo y preparar la presentación (20-30 min) — ambas tareas requieren intervención manual del equipo.
