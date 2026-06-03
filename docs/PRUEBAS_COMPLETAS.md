# Pruebas Completas (Req. 5) — CircleGuard

> Documento del **Requisito 5 — Pruebas Completas** del Proyecto Final IngeSoft V.

Este documento consolida la estrategia y los artefactos de pruebas del ecosistema CircleGuard.

---

## 1. Resumen de Capas de Pruebas

| Capa | Herramienta | Ubicación | Comando |
| :--- | :--- | :--- | :--- |
| **Unitarias** | JUnit 5 + Mockito | `services/*/src/test/java/**/service/` | `./gradlew test` |
| **Integración** | JUnit 5 + Testcontainers | `services/*/src/test/java/**/integration/` | `./gradlew integrationTest` |
| **E2E / Contrato API** | Newman (Postman) | [`e2e/circleguard-e2e.postman_collection.json`](../e2e/circleguard-e2e.postman_collection.json) | `newman run e2e/circleguard-e2e.postman_collection.json` |
| **Rendimiento / Estrés** | Locust | [`performance/locust/locustfile.py`](../performance/locust/locustfile.py) | `locust -f performance/locust/locustfile.py` |
| **Seguridad Web** | OWASP ZAP | [`security/zap-scan.sh`](../security/zap-scan.sh) | `./security/zap-scan.sh` |
| **Cobertura** | JaCoCo 0.8.11 | `services/*/build/reports/jacoco/` | Generado automáticamente al correr `test` |

---

## 2. Pruebas Unitarias

Cada microservicio contiene tests unitarios usando **JUnit 5** y **Mockito**. Se excluyen automáticamente los tests de integración (anotados con `@Tag("integration")`) para que esta suite sea rápida y sin dependencias externas.

### Clases de test por servicio

| Servicio | Clases de Test |
| :--- | :--- |
| **auth-service** | `JwtTokenServiceTest`, `QrTokenServiceTest`, `LoginControllerTest` |
| **identity-service** | `IdentityVaultServiceTest`, `IdentityEncryptionConverterTest`, `IdentityVaultControllerTest`, `IdentityMappingRepositoryTest` |
| **promotion-service** | `HealthStatusServiceTest`, `StatusLifecycleTest`, `MacSessionRegistryTest`, `HealthStatusReevaluationTest`, `FloorServiceTest`, `AdministrativeCorrectionTest`, `HealthStatusControllerTest`, `SurveyListenerTest` |
| **notification-service** | `NotificationDispatcherTest`, `TemplateServiceTest`, `NotificationRetryTest`, `ExposureNotificationListenerTest`, `PriorityAlertListenerTest`, `LmsServiceTest`, `RoomReservationServiceTest` |
| **form-service** | `HealthSurveyServiceTest`, `SymptomMapperTest`, `QuestionnaireControllerTest`, `HealthSurveyControllerTest`, `AttachmentControllerTest` |
| **gateway-service** | `QrValidationServiceTest`, `GateControllerTest` |
| **dashboard-service** | `AnalyticsControllerTest` |
| **file-service** | `FileUploadControllerTest` |

### Ejecución
```bash
# Todos los servicios en paralelo
./gradlew test

# Un servicio específico
./gradlew :services:circleguard-auth-service:test
```

---

## 3. Pruebas de Integración (Testcontainers)

Las pruebas de integración levantan contenedores efímeros de PostgreSQL, Neo4j y Kafka. Están marcadas con `@Tag("integration")` y se ejecutan con la tarea dedicada `integrationTest`.

| Servicio | Clase de Integración |
| :--- | :--- |
| **auth-service** | `AuthIdentityContractIntegrationTest` |
| **promotion-service** | `PromotionSurveyListenerIntegrationTest`, `PromotionNotificationEventIntegrationTest` |
| **form-service** | `FormPromotionEventIntegrationTest` |
| **gateway-service** | `GatewayRedisIntegrationTest` |

### Ejecución
```bash
./gradlew integrationTest
```

---

## 4. Pruebas E2E con Newman (Postman)

La colección E2E en [`e2e/circleguard-e2e.postman_collection.json`](../e2e/circleguard-e2e.postman_collection.json) valida flujos completos de usuario contra los servicios corriendo localmente.

### Flujos cubiertos
1. Handoff de visitante anónimo (`POST /api/v1/auth/visitor/handoff`)
2. Listado de cuestionarios activos (`GET /api/v1/questionnaires`)
3. Envío de formulario de síntomas (`POST /api/v1/surveys`)
4. Validación de acceso por código QR en el Gateway (`POST /api/v1/gate/validate`)
5. Smoke test de estado de salud (`GET /api/v1/health-status/stats`)

### Ejecución
```bash
# Instalar runner (solo primera vez)
npm install -g newman

# Correr la colección
newman run e2e/circleguard-e2e.postman_collection.json
```

---

## 5. Pruebas de Rendimiento y Estrés (Locust)

Las pruebas de carga en [`performance/locust/locustfile.py`](../performance/locust/locustfile.py) simulan usuarios concurrentes realizando acciones clave del sistema.

### Resultados del benchmark (20 usuarios, 2 minutos)

| Endpoint | Resultado | Tiempo promedio |
| :--- | :--- | :--- |
| `GET /api/v1/health-status/stats` | 0 fallos | ~17 ms |
| `GET /api/v1/questionnaires` | 0 fallos | ~12 ms |
| `POST /api/v1/auth/visitor/handoff` | 0 fallos | ~8 ms |
| `POST /api/v1/gate/validate` | 0 fallos | ~8 ms |
| `POST /api/v1/surveys` | 0 fallos | ~19 ms |

### Ejecución
```bash
# Modo headless con reporte HTML (100 usuarios, 5 min)
locust -f performance/locust/locustfile.py \
  --headless -u 100 -r 10 -t 5m \
  --host http://localhost:8180 \
  --html performance/locust/report.html
```

---

## 6. Pruebas de Seguridad (OWASP ZAP)

Los escaneos de seguridad web están documentados en [`security/README.md`](../security/README.md) y se ejecutan mediante contenedores Docker oficiales de ZAP.

### En el pipeline de Jenkins
- **Stage** (`Jenkinsfile.stage`): Escaneo **advisory** — advierte pero no bloquea el build.
- **Master** (`Jenkinsfile.master`): Escaneo **gate** — marca el build como `UNSTABLE` si encuentra alertas antes de la aprobación manual de producción.

### Ejecución local
```bash
# Linux / macOS
./security/zap-scan.sh

# Windows
security\zap-scan.bat
```

---

## 7. Cobertura de Código (JaCoCo)

El plugin **JaCoCo 0.8.11** se aplica automáticamente a todos los subproyectos en [`build.gradle.kts`](../build.gradle.kts). Cada vez que corres `./gradlew test`, el reporte se genera automáticamente.

### Reportes generados
| Formato | Ruta | Propósito |
| :--- | :--- | :--- |
| **XML** | `services/<nombre>/build/reports/jacoco/test/jacocoTestReport.xml` | Ingestado por SonarQube |
| **HTML** | `services/<nombre>/build/reports/jacoco/test/html/index.html` | Revisión visual local |

### Visualización en Jenkins
Los pipelines archivan automáticamente los XMLs y publican el reporte HTML como artifact navegable bajo el nombre **"Coverage Report (auth-service)"** en la UI de Jenkins.
