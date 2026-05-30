# CI/CD Avanzado — CircleGuard

> Documento del **Requisito 4 — CI/CD Avanzado (15%)** del Proyecto Final IngeSoft V.

## 1. Arquitectura de pipelines

```
              feature branch
                    │
                    ▼
       ┌──────────────────────┐
       │  Jenkinsfile.dev     │   advisory checks, deploy circleguard-dev
       └──────────────────────┘
                    │   (merge a stage)
                    ▼
       ┌──────────────────────┐
       │  Jenkinsfile.stage   │   integration tests, deploy circleguard-stage
       └──────────────────────┘
                    │   (merge a master)
                    ▼
       ┌──────────────────────┐
       │  Jenkinsfile.master  │   ⛔ APROBACION MANUAL → deploy circleguard-master
       │                      │   + Trivy gate (HIGH/CRITICAL = fail)
       │                      │   + git tag opcional
       │                      │   + release notes
       └──────────────────────┘
```

## 2. Stages por canal

| Stage | dev | stage | master |
|---|:-:|:-:|:-:|
| Checkout + carga `shared.groovy` | ✅ | ✅ | ✅ |
| Build Gradle (`bootJar`) | ✅ | ✅ | ✅ |
| Unit Tests | ✅ | ✅ | ✅ |
| Integration Tests | — | ✅ | ✅ |
| **SonarQube Analysis** | ✅ | ✅ | ✅ |
| Build Docker Images | ✅ | ✅ | ✅ |
| **Trivy Container Scan** | ✅ advisory | ✅ advisory | ✅ **gate** |
| **Approval Production** | — | — | ✅ |
| Deploy Kubernetes | ✅ dev ns | ✅ stage ns | ✅ master ns |
| Smoke Tests | auth solo | 6 services | 6 services |
| Release Notes | — | — | ✅ |
| **Git Tag** | — | — | ✅ opcional |
| **Failure Notification** | ✅ post | ✅ post | ✅ post |

## 3. Mejoras respecto al estado anterior

| Subitem del Req. 4 | Antes | Ahora |
|---|---|---|
| Pipelines completos | ✅ ya estaba | ✅ refactorizado con `jenkins/shared.groovy` |
| Ambientes separados | ✅ ya estaba | ✅ + promoción controlada via approval gate |
| SonarQube | ❌ | ✅ `runSonarAnalysis()` condicional |
| Trivy | ❌ | ✅ `runTrivyScan()` con gate en master |
| Versionado semántico | ❌ (`:local`) | ✅ `computeVersion(channel)` |
| Notificaciones de fallo | ❌ | ✅ `notifyOnFailure()` en `post.failure` |
| Aprobación a prod | ❌ | ✅ `input` stage en master |

## 4. Versionado semántico automático

Implementado en [`jenkins/shared.groovy`](../jenkins/shared.groovy) → `computeVersion(channel)`:

| Canal | Esquema | Ejemplo |
|---|---|---|
| `dev` | `0.0.0-dev.<shortSha>` | `0.0.0-dev.a1b2c3d` |
| `stage` | `<lastTag>-rc.<buildNumber>` | `v1.2.3-rc.47` |
| `master` | `<lastTag>` con patch +1 (sin la `v`) | `1.2.4` |

El master pipeline puede publicar el tag git correspondiente cuando se ejecuta con `CREATE_GIT_TAG=true`. Esto requiere credenciales git con permiso de push en el agente.

## 5. SonarQube

### Configuración

- [`sonar-project.properties`](../sonar-project.properties) define el proyecto multi-módulo con un sub-módulo Sonar por cada microservicio.
- Cada módulo exporta sources, tests, binaries, junit reports y jacoco XML.

### Cómo habilitarlo en Jenkins

1. **Levantar SonarQube** (local o remoto). Para local rápido:
   ```bash
   docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
   ```
2. **Crear un token** en SonarQube → Account → Security → Generate Tokens.
3. **Guardar el token** en Jenkins → Manage Jenkins → Credentials → Secret text con id `sonar-token`.
4. **Exportar las variables** en el `environment {}` de los Jenkinsfiles (descomentar las líneas):
   ```groovy
   SONAR_HOST_URL = 'http://sonarqube:9000'
   SONAR_TOKEN = credentials('sonar-token')
   ```
5. **Instalar `sonar-scanner`** en el agente Jenkins (`sonar-scanner-cli` desde sonarsource.com o `apt install sonar-scanner`).

Si falta cualquiera de los anteriores, el stage **emite un warning y continúa** (no bloquea el build).

## 6. Trivy

### Configuración

- Implementado en `shared.groovy` → `runTrivyScan(tag, failOnHigh)`.
- **dev / stage:** `failOnHigh=false` (sólo reporta CRITICAL como advisory).
- **master:** `failOnHigh=true` (HIGH y CRITICAL fallan el build → ningún CVE alto llega a prod).

### Instalación del binario en el agente

```bash
# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# Windows (Scoop)
scoop install trivy
```

Si `trivy` no está en `PATH`, el stage emite warning y continúa.

## 7. Notificaciones de fallos

Implementado en `shared.groovy` → `notifyOnFailure()`. Se dispara desde `post { failure { ... } }` en los 3 pipelines.

### Configuración

1. Instalar el plugin **Email Extension Plugin** (`emailext`) en Jenkins.
2. Configurar **Manage Jenkins → System → Extended E-mail Notification** con SMTP.
3. Definir destinatarios:
   - Recomendado: variable de entorno `NOTIFICATION_RECIPIENTS = 'devops@example.com,sre@example.com'` en cada Jenkinsfile, o como credential Jenkins.

El cuerpo del email incluye: job, build, branch, commit, resultado, link a consola.

Si falta `NOTIFICATION_RECIPIENTS` o el plugin, **emite warning y continúa** (no causa que un build "verde con falla de notificación" se marque como rojo).

## 8. Aprobaciones para producción

Implementado en [`Jenkinsfile.master`](../Jenkinsfile.master) stage `Approval to Deploy Production`:

```groovy
input(
    message: "Aprobar despliegue a PRODUCCION ... con imagen ${env.IMAGE_TAG}?",
    ok: 'Desplegar',
    submitter: 'admin,release-manager,@circleguard-admins',
    submitterParameter: 'APPROVED_BY'
)
```

Características:
- **Timeout 60 minutos** — si nadie aprueba, el build se aborta.
- **Submitters restringidos** — sólo usuarios o grupos listados pueden aprobar.
- **Auditoría** — el usuario que aprobó queda en `${env.APPROVED_BY}` y aparece en los logs.

## 9. shared.groovy — extracción de código común

Antes cada Jenkinsfile tenía ~150 líneas duplicadas (`runCommand`, `runGradle`, `buildDockerImages`, `kubectlApply`, `smokeTest`, etc.). Ahora todos cargan [`jenkins/shared.groovy`](../jenkins/shared.groovy):

```groovy
stage('Checkout') {
    steps {
        checkout scm
        script {
            lib = load 'jenkins/shared.groovy'
            env.IMAGE_TAG = lib.computeVersion('dev')   // o stage, master
        }
    }
}
```

Funciones expuestas: `runCommand`, `runGradle`, `computeVersion`, `buildDockerImages`, `runTrivyScan`, `runSonarAnalysis`, `hasKubectl`, `kubectlApply`, `rolloutAll`, `smokeTest`, `smokeTestAllServices`, `generateReleaseNotes`, `validateReleaseNotes`, `tagGitRelease`, `notifyOnFailure`.

## 10. Cumplimiento del Req. 4

| Subitem | Estado |
|---|---|
| Implementar pipelines completos | ✅ Jenkins (dev/stage/master) |
| Ambientes separados con promoción controlada | ✅ namespaces + approval gate en master |
| SonarQube para análisis estático | ✅ `runSonarAnalysis()` + `sonar-project.properties` |
| Trivy para escaneo de contenedores | ✅ `runTrivyScan()` con gate en prod |
| Versionado semántico automático | ✅ `computeVersion(channel)` + tag git opcional |
| Notificaciones para fallos | ✅ `notifyOnFailure()` en `post.failure` |
| Aprobaciones para despliegues a producción | ✅ `input` stage con submitters y timeout |

## 11. Tradeoffs

| Decisión | Alternativa descartada | Razón |
|---|---|---|
| Stages condicionales con skip+warning | Hard-fail si falta Sonar/Trivy/kubectl | Permite ejecutar el pipeline en agentes sin todas las herramientas (útil para PR builds y dev local) |
| `shared.groovy` por `load()` | Shared Library global Jenkins | No requiere configuración del controller; el archivo viaja con el repo |
| Git tag opcional (`CREATE_GIT_TAG` param) | Tag siempre | Permite re-ejecutar el master pipeline sin colisión de tags duplicados |
| Trivy gate sólo en master | Gate en todos | Mantener velocidad de iteración en dev/stage; bloquear sólo justo antes de prod |
| Aprobador parametrizable, no hard-coded | Approver fijo | El equipo cambia; mejor configurarlo desde el job |
