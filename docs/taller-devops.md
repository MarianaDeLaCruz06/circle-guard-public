# Informe Taller DevOps - CircleGuard

## 1. Introduccion

CircleGuard es un monorepo academico basado en microservicios Spring Boot. El sistema modela un flujo de control sanitario y acceso, donde diferentes servicios se encargan de autenticacion, identidad, formularios de salud, promocion de estados, notificaciones y validacion de ingreso por gateway.

El objetivo del taller fue preparar una base DevOps funcional y documentable para pruebas y lanzamiento. El trabajo se enfoco en estabilizar pruebas, dockerizar servicios, crear manifiestos Kubernetes simples, configurar pipelines Jenkins para tres ambientes y agregar pruebas nuevas de unidad, integracion, E2E y rendimiento.

Tecnologias utilizadas:

- Java 21.
- Spring Boot 3.2.4.
- Gradle Kotlin DSL.
- JUnit 5 y Mockito.
- Docker y Docker Compose.
- Kubernetes con manifiestos YAML.
- Jenkins declarative pipelines.
- PostgreSQL, Redis, Neo4j, Kafka y Zookeeper.
- Postman/Newman para pruebas E2E HTTP.
- Locust para pruebas de rendimiento.

## 2. Arquitectura del sistema

El taller se trabajo sobre seis microservicios principales:

- `circleguard-auth-service`: autenticacion, generacion de JWT y tokens QR.
- `circleguard-identity-service`: manejo de identidades y mapeos anonimos.
- `circleguard-form-service`: cuestionarios, encuestas de salud y publicacion de eventos.
- `circleguard-promotion-service`: evaluacion y promocion de estado de salud.
- `circleguard-notification-service`: consumo de eventos y despacho de notificaciones.
- `circleguard-gateway-service`: validacion de ingreso usando QR y Redis.

Diagrama conceptual:

```text
Usuario / Cliente
      |
      v
Auth Service -----> Identity Service
      |                    |
      v                    v
 Form Service ------> Promotion Service -----> Notification Service
      |                    |
      v                    v
   Kafka              Redis / Neo4j
                           |
                           v
                    Gateway Service
```

Flujo principal entre servicios:

1. `Auth` autentica al usuario y genera tokens JWT o QR.
2. `Identity` mantiene la relacion entre identidad real e identificadores anonimos.
3. `Form` expone cuestionarios activos y recibe encuestas de salud.
4. `Form` publica eventos como `survey.submitted`.
5. `Promotion` consume eventos, cambia estados de salud y publica eventos de estado.
6. `Notification` consume eventos de promocion o alertas para notificar.
7. `Gateway` valida QR y consulta informacion temporal en Redis para permitir o rechazar ingreso.

## 3. Configuracion del entorno

### Jenkins

Se crearon tres pipelines declarativos:

- `Jenkinsfile.dev`
- `Jenkinsfile.stage`
- `Jenkinsfile.master`

Cada pipeline usa los seis servicios definidos en la variable `SERVICES` y despliega en un namespace Kubernetes distinto mediante la variable `KUBE_NAMESPACE`.

### Docker

Cada microservicio seleccionado tiene su propio `Dockerfile` en su carpeta de servicio. Las imagenes se construyen desde la raiz del repositorio para que Gradle pueda resolver correctamente el monorepo.

Comando base:

```powershell
docker build -f services/circleguard-auth-service/Dockerfile -t circleguard-auth-service:local .
```

El mismo patron se repite para los otros cinco servicios.

### Kubernetes

La configuracion Kubernetes se concentro en pocos archivos:

```text
k8s/
  namespace.yaml
  config.yaml
  infrastructure.yaml
  services.yaml
```

Se definieron namespaces academicos para los ambientes:

- `circleguard-dev`
- `circleguard-stage`
- `circleguard-master`

### Docker Compose

El repositorio cuenta con `docker-compose.dev.yml` para levantar infraestructura local de apoyo. Este archivo se usa como base de desarrollo local para dependencias como PostgreSQL, Neo4j, Kafka, Zookeeper, Redis y OpenLDAP.

Comando recomendado:

```powershell
docker compose -f docker-compose.dev.yml up -d
```

## 4. Pipeline CI/CD

Los pipelines siguen una estructura incremental: `dev` ejecuta lo minimo necesario para construir y desplegar, `stage` agrega integracion y smoke tests, y `master` agrega generacion de Release Notes.

### 4.1 Jenkinsfile.dev

Stages principales:

- `Checkout`: obtiene el codigo fuente desde SCM.
- `Build Gradle`: ejecuta `bootJar` para los seis microservicios.
- `Unit Tests`: ejecuta `test` y publica resultados JUnit.
- `Build Docker Images`: construye imagenes locales con tag `:local`.
- `Deploy Kubernetes Dev`: aplica manifiestos en `circleguard-dev`, espera rollouts y lista pods/services.

Este pipeline esta orientado a validacion rapida de cambios en ambiente de desarrollo.

### 4.2 Jenkinsfile.stage

Stages principales:

- `Checkout`.
- `Build Gradle`.
- `Unit Tests`.
- `Integration Tests`: ejecuta `integrationTest` para pruebas marcadas con `@Tag("integration")`.
- `Build Docker Images`.
- `Deploy Kubernetes Stage`: despliega en `circleguard-stage`.
- `Smoke Tests`: ejecuta pruebas basicas HTTP con `curl` desde pods temporales.

Este pipeline agrega una capa de confianza antes de pasar a ambiente principal.

### 4.3 Jenkinsfile.master

Stages principales:

- `Checkout`.
- `Build Gradle`.
- `Unit Tests`.
- `Integration Tests`.
- `Build Docker Images`.
- `Deploy Kubernetes Master`: despliega en `circleguard-master`.
- `Smoke Tests`.
- `Generate Release Notes`: genera `release-notes.md` usando `git log` y lo guarda como artefacto del pipeline.

La generacion automatica de Release Notes usa los ultimos commits para dejar evidencia del cambio entregado.

## 5. Dockerizacion

La estrategia usada fue multi-stage build:

1. Stage de build:
   - Imagen base: `eclipse-temurin:21-jdk-alpine`.
   - Copia el repositorio completo.
   - Normaliza `gradlew` para evitar problemas por CRLF.
   - Ejecuta `./gradlew :services:<servicio>:bootJar --no-daemon`.

2. Stage runtime:
   - Imagen base: `eclipse-temurin:21-jre-alpine`.
   - Copia solo el JAR generado.
   - Define `SPRING_PROFILES_ACTIVE=docker`.
   - Expone el puerto real del servicio.
   - Ejecuta `java -jar /app/app.jar`.

Imagenes generadas:

| Servicio | Imagen | Puerto |
| --- | --- | --- |
| Auth | `circleguard-auth-service:local` | 8180 |
| Identity | `circleguard-identity-service:local` | 8083 |
| Form | `circleguard-form-service:local` | 8086 |
| Promotion | `circleguard-promotion-service:local` | 8088 |
| Notification | `circleguard-notification-service:local` | 8082 |
| Gateway | `circleguard-gateway-service:local` | 8087 |

Tamaño de imagenes construido localmente:

| Imagen | ID | Tamaño |
| --- | --- | --- |
| `circleguard-auth-service:local` | `44f27cc9a19b` | 391 MB |
| `circleguard-form-service:local` | `f9bdd99c9609` | 414 MB |
| `circleguard-gateway-service:local` | `976ae5350958` | 353 MB |
| `circleguard-identity-service:local` | `5145bf395902` | 421 MB |
| `circleguard-notification-service:local` | `14f0a4a13d33` | 405 MB |
| `circleguard-promotion-service:local` | `154e1aee4439` | 446 MB |

Las imagenes de los microservicios quedaron entre 353 MB y 446 MB. Este rango es razonable para servicios Spring Boot empaquetados como JAR ejecutable y ejecutados sobre Java 21 JRE Alpine.

Imagenes de infraestructura usadas en el entorno local:

| Imagen | ID | Tamaño |
| --- | --- | --- |
| `confluentinc/cp-kafka:7.6.0` | `24cdd3a7fa89` | 1.31 GB |
| `confluentinc/cp-zookeeper:7.6.0` | `9babd1c0beaf` | 1.31 GB |
| `neo4j:5.26` | `b357872da95a` | 963 MB |
| `osixia/openldap:1.5.0` | `18742e9c449c` | 373 MB |
| `postgres:16` | `71e27bf60b70` | 641 MB |
| `redis:7.2` | `37aa82f9fdff` | 174 MB |

Las imagenes mas pesadas corresponden a infraestructura externa, especialmente Kafka, Zookeeper y Neo4j. Los tamaños se obtuvieron con:

```powershell
docker images
```

La justificacion tecnica de usar `jre-alpine` en runtime es reducir superficie y peso de la imagen final, evitando incluir herramientas de compilacion en produccion.

## 6. Kubernetes

Estructura creada:

- `k8s/namespace.yaml`: define `circleguard-dev`, `circleguard-stage` y `circleguard-master`.
- `k8s/config.yaml`: contiene `ConfigMap` compartido y `Secret` academico.
- `k8s/infrastructure.yaml`: contiene dependencias de infraestructura.
- `k8s/services.yaml`: contiene Deployments y Services de los seis microservicios.

ConfigMap y Secret:

- `circleguard-config`: perfil `docker`, hosts internos, Kafka, Redis, Neo4j y URL de Auth.
- `circleguard-secret`: credenciales academicas para PostgreSQL, Neo4j, JWT y QR.

Infraestructura incluida:

- PostgreSQL `postgres:16`, puerto `5432`.
- Redis `redis:7.2`, puerto `6379`.
- Neo4j `neo4j:5.26`, puertos `7474` y `7687`.
- Zookeeper `confluentinc/cp-zookeeper:7.6.0`, puerto `2181`.
- Kafka `confluentinc/cp-kafka:7.6.0`, puerto `9092`.

Deployments y Services:

- Todos los servicios usan `imagePullPolicy: IfNotPresent`.
- Las imagenes apuntan a tags locales `:local`.
- Cada Service apunta al Deployment correspondiente mediante labels/selectors.
- Los puertos se mantuvieron segun la configuracion real de cada microservicio.

Aplicacion manual en dev:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -n circleguard-dev -f k8s/config.yaml
kubectl apply -n circleguard-dev -f k8s/infrastructure.yaml
kubectl apply -n circleguard-dev -f k8s/services.yaml
```

Verificacion:

```powershell
kubectl get pods -n circleguard-dev
kubectl get svc -n circleguard-dev
kubectl logs -n circleguard-dev deployment/circleguard-auth-service
```

## 7. Estrategia de pruebas

### 7.1 Pruebas unitarias

Las pruebas unitarias validan componentes individuales sin depender de infraestructura externa. Se usaron JUnit 5 y Mockito.

Pruebas agregadas:

- `JwtTokenServiceTest`: valida generacion/lectura basica de token JWT.
- `QrTokenServiceTest`: valida generacion o comportamiento esperado de token QR.
- `IdentityVaultServiceTest`: valida comportamiento de servicio de identidad usando repositorios mockeados.
- `HealthSurveyServiceTest`: valida guardado/procesamiento de encuestas de salud.
- `MacSessionRegistryTest`: valida registro y consulta de sesiones MAC.

Tambien se mantuvieron pruebas existentes en controladores, listeners y servicios.

### 7.2 Pruebas de integracion

Las pruebas de integracion se marcaron con `@Tag("integration")` y se ejecutan con el task `integrationTest`. Para mantener el taller controlado, se usaron mocks cuando era posible y se separaron pruebas pesadas de Testcontainers con tags propios.

Pruebas de integracion agregadas:

- `AuthIdentityContractIntegrationTest`: valida el contrato de comunicacion Auth -> Identity.
- `FormPromotionEventIntegrationTest`: valida publicacion de evento desde Form hacia Promotion.
- `PromotionNotificationEventIntegrationTest`: valida evento de cambio de estado hacia Notification.
- `GatewayRedisIntegrationTest`: valida integracion logica Gateway -> Redis.
- `PromotionSurveyListenerIntegrationTest`: valida evento `certificate.validated` con `APPROVED` y llamada a `updateStatus(id, "ACTIVE")`.

Adicionalmente, `SurveyListenerTest` conserva un caso unitario equivalente para validar el listener en aislamiento.

### 7.3 Pruebas E2E

Se creo una coleccion Postman:

```text
e2e/circleguard-e2e.postman_collection.json
```

Flujos incluidos:

- `visitor handoff`.
- `questionnaire active`.
- `submit survey`.
- `validate gateway`.
- `health status basico`.

Ejecucion con Newman:

```powershell
newman run e2e/circleguard-e2e.postman_collection.json
```

Estas pruebas requieren que la aplicacion este levantada, ya sea localmente o en Kubernetes con acceso a los servicios.

### 7.4 Pruebas de rendimiento

Se creo:

```text
performance/locust/locustfile.py
```

Escenarios incluidos:

- Login.
- Consulta de cuestionario.
- Envio de encuesta.
- Validacion de QR / gateway.

Metricas esperadas:

- Latencia promedio.
- Percentil 95.
- Throughput en requests por segundo.
- Tasa de errores.

Ejecucion:

```powershell
locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --html performance/locust/report.html
```

## 8. Resultados

Pruebas unitarias ejecutadas para los seis servicios:

```powershell
.\gradlew.bat :services:circleguard-auth-service:test :services:circleguard-identity-service:test :services:circleguard-form-service:test :services:circleguard-promotion-service:test :services:circleguard-notification-service:test :services:circleguard-gateway-service:test
```

Resultado obtenido: `BUILD SUCCESSFUL`.

Pruebas de integracion ligeras ejecutadas:

```powershell
.\gradlew.bat :services:circleguard-auth-service:integrationTest :services:circleguard-form-service:integrationTest :services:circleguard-promotion-service:integrationTest :services:circleguard-gateway-service:integrationTest
```

Resultado obtenido: `BUILD SUCCESSFUL`.

Verificacion especifica de la quinta prueba de integracion:

```powershell
.\gradlew.bat :services:circleguard-promotion-service:integrationTest
```

Resultado obtenido: `BUILD SUCCESSFUL`, incluyendo `PromotionSurveyListenerIntegrationTest`.

Despliegue en Kubernetes:

- Los manifiestos quedaron listos para aplicarse con `kubectl`.
- Jenkins aplica los mismos cuatro archivos parametrizando el namespace por ambiente.
- La verificacion se realiza con `kubectl rollout status`, `kubectl get pods` y `kubectl get svc`.

Ejecucion de pipelines:

- Los Jenkinsfiles quedaron listos para configurarse como jobs independientes o multibranch pipelines.
- La ejecucion real depende de tener Jenkins con Docker, Gradle/JDK, `kubectl` y credenciales de acceso al cluster.

## 9. Problemas encontrados y soluciones

### Tests fallando

Se encontraron fallos en pruebas existentes por configuracion de test, seguridad o dependencias externas. Se corrigio de forma minima priorizando mocks, perfiles de test y separacion de suites.

### CRLF en Docker

En Windows, `gradlew` puede quedar con saltos de linea CRLF y fallar dentro de imagenes Linux. Los Dockerfiles ejecutan:

```sh
sed -i 's/\r$//' gradlew
```

Esto normaliza el wrapper antes de ejecutar Gradle.

### Testcontainers

Algunas pruebas existentes de `promotion-service` usan Testcontainers y fallan si Docker no esta disponible. Para no bloquear la suite academica de integracion liviana:

- Las pruebas con contenedores se etiquetaron como `container`.
- La prueba de rendimiento basada en contenedor se etiqueto como `performance`.
- El task `test` excluye `integration`, `container` y `performance`.
- El task `integrationTest` ejecuta solo `@Tag("integration")`.

### localhost hardcodeado

Algunos contratos usan endpoints locales, por ejemplo para simular comunicacion entre servicios. En las pruebas nuevas se mantuvo el enfoque minimo, usando servidores/mocks locales cuando aplica. En Kubernetes, los manifiestos usan DNS interno por nombre de servicio, por ejemplo `circleguard-auth-service`, `kafka`, `redis` y `neo4j`.

## 10. Conclusiones

El taller permitio construir una base DevOps completa y controlada para CircleGuard sin redisenar la arquitectura. Se logro:

- Estabilizar pruebas existentes.
- Agregar pruebas unitarias, de integracion, E2E y rendimiento.
- Dockerizar seis microservicios con Java 21.
- Crear manifiestos Kubernetes academicos y funcionales.
- Preparar pipelines Jenkins para `dev`, `stage` y `master`.
- Generar Release Notes automaticamente desde Git.

La principal leccion es que CI/CD no depende solo de scripts, sino de separar correctamente tipos de prueba, aislar dependencias externas y mantener configuraciones reproducibles.

Mejoras futuras:

- Publicar imagenes en un registry real.
- Agregar health checks HTTP a los Deployments.
- Parametrizar secretos con un gestor externo.
- Ejecutar Newman y Locust directamente desde Jenkins.
- Reemplazar endpoints hardcodeados por configuracion externa.
- Agregar persistencia con PersistentVolumes para bases de datos en Kubernetes.

## 11. Anexos

### Gradle

Ejecutar pruebas unitarias de los seis servicios:

```powershell
.\gradlew.bat :services:circleguard-auth-service:test :services:circleguard-identity-service:test :services:circleguard-form-service:test :services:circleguard-promotion-service:test :services:circleguard-notification-service:test :services:circleguard-gateway-service:test
```

Ejecutar pruebas de integracion:

```powershell
.\gradlew.bat :services:circleguard-auth-service:integrationTest :services:circleguard-form-service:integrationTest :services:circleguard-promotion-service:integrationTest :services:circleguard-gateway-service:integrationTest
```

Construir JARs:

```powershell
.\gradlew.bat :services:circleguard-auth-service:bootJar :services:circleguard-identity-service:bootJar :services:circleguard-form-service:bootJar :services:circleguard-promotion-service:bootJar :services:circleguard-notification-service:bootJar :services:circleguard-gateway-service:bootJar
```

### Docker

Construir imagenes:

```powershell
docker build -f services/circleguard-auth-service/Dockerfile -t circleguard-auth-service:local .
docker build -f services/circleguard-identity-service/Dockerfile -t circleguard-identity-service:local .
docker build -f services/circleguard-form-service/Dockerfile -t circleguard-form-service:local .
docker build -f services/circleguard-promotion-service/Dockerfile -t circleguard-promotion-service:local .
docker build -f services/circleguard-notification-service/Dockerfile -t circleguard-notification-service:local .
docker build -f services/circleguard-gateway-service/Dockerfile -t circleguard-gateway-service:local .
```

Listar imagenes:

```powershell
docker images | Select-String "circleguard"
```

Levantar infraestructura local:

```powershell
docker compose -f docker-compose.dev.yml up -d
```

### Kubernetes

Aplicar en dev:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -n circleguard-dev -f k8s/config.yaml
kubectl apply -n circleguard-dev -f k8s/infrastructure.yaml
kubectl apply -n circleguard-dev -f k8s/services.yaml
```

Aplicar en stage:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -n circleguard-stage -f k8s/config.yaml
kubectl apply -n circleguard-stage -f k8s/infrastructure.yaml
kubectl apply -n circleguard-stage -f k8s/services.yaml
```

Aplicar en master:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -n circleguard-master -f k8s/config.yaml
kubectl apply -n circleguard-master -f k8s/infrastructure.yaml
kubectl apply -n circleguard-master -f k8s/services.yaml
```

Verificar recursos:

```powershell
kubectl get pods -n circleguard-dev
kubectl get svc -n circleguard-dev
kubectl rollout status deployment/circleguard-auth-service -n circleguard-dev
kubectl logs -n circleguard-dev deployment/circleguard-auth-service
```

### Newman

```powershell
newman run e2e/circleguard-e2e.postman_collection.json
```

### Locust

```powershell
locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --html performance/locust/report.html
```

### Jenkins

Crear tres jobs o pipelines apuntando a:

- `Jenkinsfile.dev`
- `Jenkinsfile.stage`
- `Jenkinsfile.master`

Requisitos del agente Jenkins:

- JDK 21.
- Docker CLI/daemon disponible.
- `kubectl` configurado contra el cluster.
- Acceso al repositorio Git.
