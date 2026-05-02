# Guia de evidencias para el taller DevOps - CircleGuard

Este documento explica paso a paso como preparar las evidencias que pide el taller:

- Configuracion de pipelines.
- Pantallazos de configuracion relevante.
- Pantallazos de ejecucion exitosa.
- Analisis de resultados de pruebas, incluyendo rendimiento.

## 1. Preparacion previa

Antes de tomar evidencias, verifica que el repositorio tenga estos archivos:

```text
Jenkinsfile.dev
Jenkinsfile.stage
Jenkinsfile.master
k8s/namespace.yaml
k8s/config.yaml
k8s/infrastructure.yaml
k8s/services.yaml
e2e/circleguard-e2e.postman_collection.json
performance/locust/locustfile.py
```

Tambien verifica que las imagenes Docker existan:

```bash
docker images
```

Debes ver imagenes como:

```text
circleguard-auth-service:local
circleguard-identity-service:local
circleguard-form-service:local
circleguard-promotion-service:local
circleguard-notification-service:local
circleguard-gateway-service:local
```

## 2. Evidencia de configuracion de pipelines

La seccion "Configuracion" del informe debe mostrar el texto de configuracion de los pipelines y pantallazos de Jenkins.

### 2.1 Texto de configuracion que debes incluir

En el informe, agrega una subseccion por pipeline:

```markdown
### Jenkinsfile.dev

Este pipeline ejecuta checkout, build Gradle, pruebas unitarias, construccion de imagenes Docker y despliegue en Kubernetes sobre el namespace circleguard-dev.

Archivo usado: Jenkinsfile.dev
Namespace: circleguard-dev
Servicios:
- circleguard-auth-service
- circleguard-identity-service
- circleguard-form-service
- circleguard-promotion-service
- circleguard-notification-service
- circleguard-gateway-service
```

Repite lo mismo para:

- `Jenkinsfile.stage`, con namespace `circleguard-stage`.
- `Jenkinsfile.master`, con namespace `circleguard-master`.

### 2.2 Pantallazos de configuracion en Jenkins

Para cada pipeline en Jenkins, toma estos pantallazos:

1. Pantallazo de la pantalla principal del job.
   - Debe verse el nombre del job, por ejemplo `CircleGuard Dev`.

2. Pantallazo de la configuracion del pipeline.
   - Entra a `Configure`.
   - Muestra la seccion `Pipeline`.
   - Debe verse si el pipeline usa SCM o script desde repositorio.

3. Pantallazo del archivo Jenkinsfile seleccionado.
   - Si usas Multibranch Pipeline, muestra la rama.
   - Si usas Pipeline from SCM, muestra el `Script Path`:
     - `Jenkinsfile.dev`
     - `Jenkinsfile.stage`
     - `Jenkinsfile.master`

4. Pantallazo de credenciales o herramientas relevantes, si aplica.
   - Docker disponible en el agente.
   - `kubectl` configurado.
   - JDK 21 disponible.

No es necesario mostrar secretos reales. Si aparece informacion sensible, ocultala.

## 3. Como crear los jobs en Jenkins

### 3.1 Job para dev

1. Abre Jenkins.
2. Selecciona `New Item`.
3. Nombre sugerido: `CircleGuard Dev`.
4. Tipo: `Pipeline`.
5. En `Pipeline`, selecciona `Pipeline script from SCM`.
6. SCM: Git.
7. Repository URL: URL del repositorio CircleGuard.
8. Branch: rama del taller, por ejemplo:

```text
feature/taller2-pipelines-testing-release
```

9. Script Path:

```text
Jenkinsfile.dev
```

10. Guarda el job.

### 3.2 Job para stage

Repite el proceso anterior con:

```text
Nombre: CircleGuard Stage
Script Path: Jenkinsfile.stage
```

### 3.3 Job para master

Repite el proceso anterior con:

```text
Nombre: CircleGuard Master
Script Path: Jenkinsfile.master
```

## 4. Evidencia de ejecucion exitosa

La seccion "Resultado" debe incluir pantallazos de ejecuciones exitosas de los pipelines.

### 4.1 Ejecutar pipeline dev

En Jenkins:

1. Entra al job `CircleGuard Dev`.
2. Haz clic en `Build Now`.
3. Espera a que termine.
4. Abre la ejecucion.
5. Entra a `Console Output`.

Pantallazos recomendados:

- Vista del build con estado `Success`.
- Stage View mostrando stages en verde.
- Consola mostrando:
  - `Build Gradle`.
  - `Unit Tests`.
  - `Build Docker Images`.
  - `Deploy Kubernetes Dev`.
  - `kubectl get pods`.
  - `kubectl get svc`.

### 4.2 Ejecutar pipeline stage

En Jenkins:

1. Entra al job `CircleGuard Stage`.
2. Haz clic en `Build Now`.
3. Espera a que termine.
4. Abre la ejecucion.
5. Revisa `Console Output` y resultados JUnit.

Pantallazos recomendados:

- Build exitoso.
- Stage View con:
  - `Unit Tests`.
  - `Integration Tests`.
  - `Deploy Kubernetes Stage`.
  - `Smoke Tests`.
- Resultados JUnit publicados.
- Consola mostrando `BUILD SUCCESSFUL`.

### 4.3 Ejecutar pipeline master

En Jenkins:

1. Entra al job `CircleGuard Master`.
2. Haz clic en `Build Now`.
3. Espera a que termine.
4. Abre la ejecucion.
5. Revisa que se haya generado el artefacto `release-notes.md`.

Pantallazos recomendados:

- Build exitoso.
- Stage View con todos los stages en verde.
- Stage `Generate Release Notes`.
- Artefacto archivado `release-notes.md`.
- Consola mostrando el comando `git log` o la generacion de Release Notes.

## 5. Evidencia de Kubernetes

Despues del despliegue, toma pantallazos de estos comandos:

```bash
kubectl get namespaces
kubectl get pods -n circleguard-dev
kubectl get svc -n circleguard-dev
```

Para stage:

```bash
kubectl get pods -n circleguard-stage
kubectl get svc -n circleguard-stage
```

Para master:

```bash
kubectl get pods -n circleguard-master
kubectl get svc -n circleguard-master
```

Tambien puedes mostrar el estado de un despliegue:

```bash
kubectl rollout status deployment/circleguard-auth-service -n circleguard-dev
```

Y logs:

```bash
kubectl logs -n circleguard-dev deployment/circleguard-auth-service
```

## 6. Evidencia de pruebas

### 6.1 Pruebas unitarias

Ejecuta:

```bash
./gradlew :services:circleguard-auth-service:test :services:circleguard-identity-service:test :services:circleguard-form-service:test :services:circleguard-promotion-service:test :services:circleguard-notification-service:test :services:circleguard-gateway-service:test
```

En Windows PowerShell:

```powershell
.\gradlew.bat :services:circleguard-auth-service:test :services:circleguard-identity-service:test :services:circleguard-form-service:test :services:circleguard-promotion-service:test :services:circleguard-notification-service:test :services:circleguard-gateway-service:test
```

Pantallazo requerido:

- Consola con `BUILD SUCCESSFUL`.
- Si usas Jenkins, pantalla de resultados JUnit.

Texto sugerido para el informe:

```markdown
Las pruebas unitarias validaron componentes aislados de los microservicios sin depender de infraestructura externa. Se usaron JUnit 5 y Mockito para verificar servicios como JwtTokenService, QrTokenService, IdentityVaultService, HealthSurveyService y MacSessionRegistry.
```

### 6.2 Pruebas de integracion

Ejecuta:

```powershell
.\gradlew.bat :services:circleguard-auth-service:integrationTest :services:circleguard-form-service:integrationTest :services:circleguard-promotion-service:integrationTest :services:circleguard-gateway-service:integrationTest
```

Pantallazo requerido:

- Consola con `BUILD SUCCESSFUL`.
- Reportes JUnit de `integrationTest`.

Texto sugerido:

```markdown
Las pruebas de integracion validaron contratos y colaboraciones entre servicios o componentes. Para mantener una ejecucion estable en CI, se usaron mocks y se separaron pruebas con Testcontainers en tags independientes.
```

### 6.3 Pruebas E2E

Ejecuta Newman cuando la aplicacion este desplegada:

```bash
newman run e2e/circleguard-e2e.postman_collection.json
```

Pantallazos requeridos:

- Consola con resumen de Newman.
- Total de requests.
- Total de assertions.
- Errores, si existen.

Texto sugerido:

```markdown
Las pruebas E2E simularon flujos completos por HTTP usando una coleccion Postman ejecutada con Newman. Los flujos cubren handoff de visitante, cuestionario activo, envio de encuesta, validacion por gateway y consulta basica de estado de salud.
```

## 7. Evidencia de rendimiento con Locust

### 7.1 Ejecutar Locust

Con la aplicacion desplegada, ejecuta:

```bash
locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --html performance/locust/report.html
```

Parametros:

- `-u 20`: simula 20 usuarios.
- `-r 5`: crea 5 usuarios por segundo.
- `-t 2m`: ejecuta la prueba durante 2 minutos.
- `--html`: genera reporte HTML.

Pantallazos requeridos:

- Consola de Locust al finalizar.
- Archivo `performance/locust/report.html` abierto en el navegador.
- Tabla de estadisticas por endpoint.
- Grafica o resumen de fallos.

### 7.2 Metricas que debes reportar

En el informe incluye una tabla como esta:

```markdown
| Metrica | Resultado |
| --- | --- |
| Usuarios concurrentes | 20 |
| Tiempo de ejecucion | 2 minutos |
| Requests totales | Completar con resultado de Locust |
| Throughput promedio | Completar con Requests/s |
| Tiempo promedio de respuesta | Completar con Average Response Time |
| Percentil 95 | Completar con 95% |
| Tasa de errores | Completar con Failures / Total Requests |
```

### 7.3 Como calcular tasa de errores

Si Locust muestra:

```text
Total requests: 1000
Failures: 20
```

La tasa de errores es:

```text
(20 / 1000) * 100 = 2%
```

Formula:

```text
tasa de errores = (fallos / requests totales) * 100
```

### 7.4 Texto de analisis sugerido

Usa este texto como base y reemplaza los valores:

```markdown
Durante la prueba de rendimiento se simularon 20 usuarios concurrentes durante 2 minutos. El sistema alcanzo un throughput promedio de X requests por segundo, con un tiempo promedio de respuesta de X ms y un percentil 95 de X ms. La tasa de errores fue de X%.

Los resultados indican que el sistema pudo responder bajo una carga academica controlada. Si el percentil 95 es significativamente mayor que el promedio, esto indica variabilidad en los tiempos de respuesta y posibles cuellos de botella. Si la tasa de errores supera el 5%, se recomienda revisar logs de los servicios, disponibilidad de dependencias como Kafka/Redis/PostgreSQL y limites de recursos en Kubernetes.
```

## 8. Estructura recomendada para pegar en el informe final

Puedes agregar una seccion llamada `Evidencias de configuracion y ejecucion`:

```markdown
## Evidencias de configuracion y ejecucion

### Configuracion de pipelines

Se configuraron tres pipelines Jenkins declarativos:

- Jenkinsfile.dev para circleguard-dev.
- Jenkinsfile.stage para circleguard-stage.
- Jenkinsfile.master para circleguard-master.

[Insertar pantallazo de configuracion del job dev]
[Insertar pantallazo de configuracion del job stage]
[Insertar pantallazo de configuracion del job master]

### Resultados de ejecucion

Los pipelines ejecutaron construccion Gradle, pruebas, construccion Docker y despliegue Kubernetes.

[Insertar pantallazo de Stage View dev exitoso]
[Insertar pantallazo de Stage View stage exitoso]
[Insertar pantallazo de Stage View master exitoso]

### Analisis de pruebas

Las pruebas unitarias e integracion finalizaron correctamente. Las pruebas E2E validaron flujos HTTP principales. Las pruebas de rendimiento con Locust permitieron medir latencia, throughput y tasa de errores.

[Insertar tabla de metricas Locust]
[Insertar pantallazo del reporte HTML de Locust]
```

## 9. Checklist final de evidencias

Marca cada item antes de entregar:

- [ ] Pantallazo de configuracion del job `CircleGuard Dev`.
- [ ] Pantallazo de configuracion del job `CircleGuard Stage`.
- [ ] Pantallazo de configuracion del job `CircleGuard Master`.
- [ ] Pantallazo de ejecucion exitosa de pipeline dev.
- [ ] Pantallazo de ejecucion exitosa de pipeline stage.
- [ ] Pantallazo de ejecucion exitosa de pipeline master.
- [ ] Pantallazo de resultados JUnit.
- [ ] Pantallazo de pods y services en Kubernetes.
- [ ] Pantallazo o salida de Newman.
- [ ] Pantallazo de reporte Locust.
- [ ] Tabla de metricas de rendimiento.
- [ ] Analisis escrito de latencia, throughput y tasa de errores.
- [ ] Release Notes generado como artefacto en Jenkins.
