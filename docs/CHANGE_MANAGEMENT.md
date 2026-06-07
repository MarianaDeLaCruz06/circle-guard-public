# Change Management y Release Management - CircleGuard

## Objetivo

Definir un proceso formal para solicitar, evaluar, implementar, validar, aprobar y desplegar cambios en CircleGuard, reduciendo riesgos tecnicos y dejando trazabilidad academica del ciclo de vida de releases.

Este proceso se apoya en la estrategia de branching y en los pipelines existentes:

- `Jenkinsfile.dev`
- `Jenkinsfile.stage`
- `Jenkinsfile.master`
- `jenkins/shared.groovy`
- `release-notes.md`
- `evidence/06-release/release-notes.md`

## Tipos de cambio

| Tipo | Descripcion | Ejemplo | Aprobacion requerida |
|---|---|---|---|
| Cambio normal | Cambio planificado que sigue el flujo completo dev-stage-master. | Nueva funcionalidad, mejora de pipeline, ajuste Terraform. | Revision tecnica y aprobacion antes de master. |
| Cambio urgente | Cambio necesario en corto plazo, pero con validacion minima en dev/stage. | Correccion de bug que afecta demo o despliegue. | Aprobacion del responsable tecnico. |
| Cambio de emergencia | Cambio para restaurar servicio o corregir fallo critico. | Rollback de deployment fallido. | Aprobacion posterior documentada y evidencia del rollback. |

## Flujo formal de cambios

### 1. Solicitud de cambio

Cada cambio debe describir:

- Problema u objetivo.
- Alcance funcional o tecnico.
- Servicios afectados.
- Riesgos esperados.
- Evidencia requerida para validar.

La solicitud puede documentarse como issue, tarjeta de tablero o entrada en una bitacora. Si el tablero no esta versionado, debe dejarse constancia en documentacion del repositorio.

### 2. Analisis de impacto

Antes de desarrollar se evalua impacto sobre:

- Microservicios en `services/`.
- Aplicacion movil en `mobile/`.
- Manifiestos Kubernetes en `k8s/`.
- Terraform en `terraform/`.
- Pipelines Jenkins.
- Seguridad, observabilidad y pruebas.

### 3. Desarrollo en feature branch

Los cambios normales se desarrollan en ramas:

```bash
git checkout dev
git checkout -b feature/<nombre-del-cambio>
```

La rama debe contener solo los archivos relacionados con el cambio.

### 4. Validacion en dev

Al integrar hacia `dev`, el pipeline esperado es `Jenkinsfile.dev`.

Controles esperados:

- Build Gradle.
- Pruebas unitarias.
- Analisis SonarQube si `SONAR_TOKEN` y `sonar-scanner` estan configurados.
- Build de imagenes Docker.
- Escaneo Trivy advisory si Trivy esta instalado.
- Despliegue a `circleguard-dev` si `kubectl` esta disponible.
- Smoke tests.

Evidencias relacionadas:

- `Jenkinsfile.dev`
- `evidence/01-build/backend-bootjar.txt`
- `evidence/02-tests/backend-unit-tests.txt`
- `evidence/03-kubernetes/circleguard-dev-pods.txt`
- `evidence/03-kubernetes/circleguard-dev-services.txt`

### 5. Promocion a stage

Cuando el cambio esta estable, se promueve a `stage`. El pipeline esperado es `Jenkinsfile.stage`.

Controles esperados:

- Build.
- Pruebas unitarias.
- Pruebas de integracion.
- SonarQube si esta configurado.
- Trivy advisory.
- OWASP ZAP advisory.
- Despliegue a `circleguard-stage`.
- Smoke tests completos.

Evidencias relacionadas:

- `Jenkinsfile.stage`
- `evidence/03-kubernetes/circleguard-stage-pods.txt`
- `evidence/03-kubernetes/circleguard-stage-services.txt`
- `evidence/04-security/zap-baseline-report.html`

### 6. Aprobacion para master/prod

La promocion a `master` representa el despliegue productivo academico en namespace `circleguard-master`.

El pipeline `Jenkinsfile.master` incluye una etapa de aprobacion manual:

- Stage `Approval to Deploy Production`.
- Timeout de aprobacion.
- Lista restringida de aprobadores configurada en el Jenkinsfile.

Controles esperados:

- Build.
- Pruebas unitarias.
- Pruebas de integracion.
- SonarQube si esta configurado.
- Trivy gate para HIGH/CRITICAL.
- OWASP ZAP gate/advisory antes de aprobar.
- Aprobacion manual.
- Despliegue a `circleguard-master`.
- Smoke tests.

### 7. Release notes

Las release notes se generan en el pipeline master mediante `jenkins/shared.groovy`.

Evidencias:

- `release-notes.md`
- `evidence/06-release/release-notes.md`
- Funcion `generateReleaseNotes` en `jenkins/shared.groovy`.

Contenido minimo esperado:

- Version.
- Fecha.
- Cambios principales.
- Evidencia de seguridad.
- Evidencia de observabilidad.
- Limitaciones conocidas.

### 8. Rollback si falla

Si el despliegue falla o las validaciones post-release no son aceptables, se ejecuta rollback operativo en Kubernetes.

Comando base:

```bash
kubectl rollout undo deployment/<deployment-name> -n <namespace>
```

Ejemplo:

```bash
kubectl rollout undo deployment/circleguard-auth-service -n circleguard-master
```

Verificacion posterior:

```bash
kubectl rollout status deployment/<deployment-name> -n <namespace>
kubectl get pods -n <namespace>
kubectl get svc -n <namespace>
```

Namespaces esperados:

- `circleguard-dev`
- `circleguard-stage`
- `circleguard-master`

## Estrategia de tags semanticos

La estrategia documentada en `jenkins/shared.groovy` usa versionado semantico por canal:

| Canal | Formato | Ejemplo |
|---|---|---|
| dev | `0.0.0-dev.<shortSha>` | `0.0.0-dev.a1b2c3d` |
| stage | `<lastTag>-rc.<buildNumber>` | `v1.0.0-rc.15` |
| master | incremento patch desde ultimo `vX.Y.Z` | `v1.0.1` |

El tag en Git se publica en `Jenkinsfile.master` solo si el parametro `CREATE_GIT_TAG` esta activo.

## Checklist go/no-go

| Pregunta | Go | No-go |
|---|---|---|
| Build Gradle exitoso | Continuar | Detener y corregir |
| Pruebas unitarias exitosas | Continuar | Detener y corregir |
| Pruebas de integracion exitosas en stage/master | Continuar | Detener y corregir |
| E2E o smoke tests sin fallos criticos | Continuar | Detener y corregir |
| ZAP sin hallazgos altos no aceptados | Continuar | Detener o documentar excepcion |
| Trivy sin HIGH/CRITICAL en master | Continuar | Detener release |
| Prometheus/Grafana disponibles | Continuar | Revisar observabilidad |
| Release notes generadas | Continuar | Generar antes de cerrar |
| Rollback definido | Continuar | No aprobar master |

## Limitaciones

- No se encontro evidencia versionada de tags reales publicados en remoto.
- SonarQube y Trivy estan configurados, pero su ejecucion puede omitirse si faltan binarios o credenciales en el agente Jenkins.
- El entorno productivo es academico/local; no se evidencia TLS productivo ni RBAC Kubernetes implementado.
