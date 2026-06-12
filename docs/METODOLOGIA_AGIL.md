# Metodología Ágil y Estrategia de Branching — CircleGuard

> Documento del **Requisito 1 — Metodología Ágil y Estrategia de Branching**

Este documento detalla la adopción de prácticas ágiles de gestión de proyectos y la definición de una estrategia de branching para el desarrollo del proyecto de CircleGuard.

---

## 1. Marco de Metodología Ágil: Scrum

Para la gestión de CircleGuard se adoptó el marco de trabajo **Scrum**, optimizado para el desarrollo de arquitecturas de microservicios e integraciones complejas de infraestructura.

### 1.1 Roles del Equipo
- **Product Owner (PO): Valentina**: Responsable de definir las historias de usuario en el Backlog del Producto, priorizar el valor de negocio y validar el cumplimiento de los criterios de aceptación en cada Sprint.
- **Scrum Master (SM): Mariana**: Facilitador del proceso. Asegura que el equipo comprenda la metodología, elimina impedimentos técnicos (ej. problemas de configuración en Jenkins, accesos a clústeres) y fomenta la mejora continua.
- **Development & DevOps Team: Alexis, Valentina y Mariana**: Desarrolladores encargados de codificar los microservicios en Spring Boot, crear la aplicación móvil en Expo y escribir la infraestructura como código en Terraform.

### 1.2 Ceremonias y Frecuencia
- **Sprint Planning**: Se realiza al inicio de cada sprint (duración de 2 semanas) para definir el **Sprint Goal** y seleccionar las historias de usuario del backlog que se comprometerán.
- **Daily Standup**: Sesiones de sincronización diaria de 15 minutos enfocadas en tres preguntas: ¿Qué hice ayer?, ¿Qué haré hoy?, y ¿Tengo algún impedimento?
- **Sprint Review**: Demostración funcional al final de cada sprint. El PO valida las historias de usuario.
- **Sprint Retrospective**: Reunión de cierre para analizar qué funcionó bien, qué falló y definir un plan de acción para el siguiente sprint.

### 1.3 Definición de "Hecho" (Definition of Done - DoD)
Una historia de usuario se considera terminada (`Done`) solo si cumple con los siguientes controles de calidad:
1. **Compilación y Pruebas Unitarias**: El código compila localmente y pasa el 100% de las pruebas unitarias e integración (`./gradlew test`).
2. **Revisión de Código**: Al menos un Pull Request (PR) aprobado por otro miembro del equipo.
3. **Análisis Estático (SonarQube)**: El código debe pasar el Quality Gate definido en SonarQube (sin bugs críticos ni vulnerabilidades de alta prioridad).
4. **Escaneo de Contenedores (Trivy)**: La imagen Docker generada no debe tener vulnerabilidades de severidad `HIGH` o `CRITICAL` en la rama de despliegue productivo.
5. **Despliegue Continuo**: La imagen se despliega automáticamente en el clúster de Kubernetes en el namespace respectivo y pasa la suite de Smoke Tests de Jenkins.

---

## 2. Estrategia de Branching (GitFlow Adaptado)

Adoptamos una estrategia **GitFlow adaptada** a un entorno de microservicios monorepo con despliegue automatizado multicanal en Kubernetes.

El ciclo de desarrollo de una nueva funcionalidad inicia a partir de la rama `dev`. En lugar de trabajar sobre ella directamente, los desarrolladores abren ramas temporales de corta duración con el prefijo `feature/` o `bugfix/` para cada historia de usuario. Una vez completada y probada la funcionalidad a nivel local, se realiza un Pull Request para integrar el código de vuelta a la rama `dev`.

La rama `dev` actúa como la rama principal de integración diaria del equipo. Cada cambio fusionado en esta rama dispara de manera automática el pipeline `Jenkinsfile.dev`, el cual compila los microservicios, ejecuta el análisis estático en SonarQube y corre pruebas unitarias antes de generar la imagen del contenedor y desplegarla en el namespace de desarrollo en Kubernetes (`circleguard-dev`).

Una vez que se consolida un conjunto estable de funcionalidades (por ejemplo, al finalizar el Sprint 1), se promueven los cambios hacia la rama `stage`. Esta acción de merge genera una etiqueta de pre-lanzamiento (Release Candidate como `v1.0.0-rc.1`) y activa el pipeline `Jenkinsfile.stage` para desplegar en el namespace de pre-producción (`circleguard-stage`), donde se realizan pruebas de integración de punta a punta entre los microservicios y se realiza la demostración y validación final.

Finalmente, cuando la versión en `stage` es declarada estable y segura, se promueve a la rama `master`. Esto desencadena el pipeline productivo `Jenkinsfile.master`, el cual ejecuta pruebas rigurosas, realiza un escaneo de seguridad en imágenes con Trivy (bloqueando la compilación si encuentra vulnerabilidades altas o críticas). Tras la aprobación, el código se despliega en producción (`circleguard-master`) y se le asigna su etiqueta de versión final (como `v1.1.0`).

### 2.1 Ramas del Repositorio

- **`master`**: Representa el estado estable y productivo del software. Solo recibe merges desde la rama `stage` mediante un proceso de aprobación formal. Cada merge a `master` genera un tag de versión semántica automática (ej. `v1.1.0`).
- **`stage`**: Rama de integración para pruebas previas a producción. Aquí se consolidan todas las características listas para el release final. Es el entorno de QA/Staging.
- **`dev`**: Rama principal de desarrollo diario. Integra de forma continua las características completadas por el equipo.
- **`feature/*` / `bugfix/*`**: Ramas temporales de corta duración creadas a partir de `dev`. Se utilizan para implementar historias de usuario individuales o resolver bugs específicos. Al finalizar, se realiza un Pull Request hacia `dev`.

### 2.2 Integración con los Pipelines de CI/CD (Jenkins) y Kubernetes

Nuestra estrategia de branching se mapea de forma directa e inequívoca con la infraestructura de despliegue definida en Jenkins y Kubernetes:

| Rama Git | Archivo Jenkins | Namespace K8s | Acciones y Controles del Pipeline |
| :--- | :--- | :--- | :--- |
| **`feature/*`** | *Ninguno (Local)* | *N/A (Local)* | Compilación local y ejecución de tests unitarios antes de subir al origen. |
| **`dev`** | [`Jenkinsfile.dev`](../Jenkinsfile.dev) | `circleguard-dev` | Build Gradle + Tests unitarios + SonarQube + Build Docker + Escaneo Trivy (Advisory) + Despliegue en K8s dev + Smoke Tests (Auth service). |
| **`stage`** | [`Jenkinsfile.stage`](../Jenkinsfile.stage) | `circleguard-stage` | Build Gradle + Tests unitarios e integración + SonarQube + Build Docker + Escaneo Trivy (Advisory) + Despliegue en K8s stage + Smoke Tests completos (6 servicios). |
| **`master`** | [`Jenkinsfile.master`](../Jenkinsfile.master) | `circleguard-master` | Build Gradle + Tests completos + SonarQube + Build Docker + **Trivy Gate (falla en HIGH/CRITICAL)** + **Aprobación Manual (Timeout 60 min)** + Despliegue en K8s prod + Smoke Tests + Generación de Release Notes + Tagging Git. |

---

## 3. Tablero de Gestión del Proyecto (GitHub Projects)

El tablero activo del proyecto está disponible en la pestaña **Projects** del repositorio en GitHub:

> 🔗 https://github.com/MarianaDeLaCruz06/circle-guard-public/projects

Para el seguimiento diario y visual del ciclo de vida de desarrollo, se utiliza un tablero de gestión con las siguientes columnas:
- **Backlog**: Ideas, requerimientos futuros y mejoras de fases posteriores.
- **To Do**: Tareas e historias de usuario comprometidas para el Sprint actual.
- **In Progress**: Tareas en desarrollo activo.
- **Review / QA**: Código en proceso de Pull Request o bajo análisis en el pipeline de `stage`.
- **Done**: Tareas completadas que cumplen al 100% con la Definition of Done.

Cada historia de usuario (HU) tiene sus respectivos criterios de aceptación y Definition of Done; la HU se considera terminada cuando se cumplen todos los criterios de aceptación y la DoD.