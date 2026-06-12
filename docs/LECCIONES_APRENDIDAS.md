# Lecciones Aprendidas y Recomendaciones - CircleGuard

## Lecciones tecnicas

- El enfoque de monorepo facilito coordinar microservicios, mobile, infraestructura y evidencias en un solo repositorio.
- Spring Boot Actuator y Micrometer permitieron exponer salud y metricas con baja complejidad.
- La separacion por servicios en `services/` ayudo a mapear responsabilidades: autenticacion, identidad, formularios, promocion, notificaciones, gateway, dashboard y archivos.
- La arquitectura basada en eventos con Kafka mejora desacoplamiento, pero requiere mas cuidado operativo que una comunicacion HTTP simple.
- Neo4j es adecuado para relaciones de contacto y propagacion, pero su operacion debe planearse bien si se lleva a produccion.

## Lecciones de DevOps

- Las evidencias en `evidence/` son tan importantes como la configuracion tecnica porque permiten demostrar cumplimiento.
- Separar ambientes `dev`, `stage` y `master` ayuda a explicar promocion controlada.
- Kubernetes local es util para aprender y validar, pero no representa completamente las condiciones de un cluster productivo.
- Terraform mejora la trazabilidad de infraestructura, especialmente cuando se organiza por modulos y ambientes.
- Los manifiestos `k8s/` sirven como base historica, pero Terraform deberia ser la fuente principal para infraestructura si se adopta IaC.

## Lecciones de CI/CD

- Jenkinsfiles separados por ambiente hacen mas clara la intencion de cada etapa.
- `jenkins/shared.groovy` redujo duplicacion y centralizo funciones como build, versionado, Trivy, SonarQube, smoke tests y release notes.
- Los controles condicionales son utiles en ambientes locales, pero para una entrega productiva los gates criticos no deberian omitirse silenciosamente.
- SonarQube y Trivy deben contar con evidencia de ejecucion, no solo configuracion.
- La aprobacion manual antes de `master` mejora el control de release y soporta el requisito de promocion a produccion.

## Lecciones de seguridad

- OWASP ZAP es una forma practica de cubrir seguridad web basica y generar evidencia HTML.
- Trivy es util para vulnerabilidades de contenedores y filesystem, pero su ejecucion en Windows requiere cuidado con rutas y montajes Docker.
- El RBAC implementado a nivel aplicacion no reemplaza RBAC Kubernetes.
- Los secretos Kubernetes basicos no equivalen a gestion segura de secretos para produccion.
- TLS productivo no esta implementado en la evidencia actual y debe tratarse como recomendacion pendiente.

## Lecciones de observabilidad

- Prometheus y Grafana entregan una base solida para metricas tecnicas.
- Un dashboard general ayuda a la demo, pero una operacion madura requiere dashboards por microservicio.
- Los health checks de Actuator facilitan validaciones rapidas y smoke tests.
- ELK Stack no esta implementado; se recomienda para centralizar logs.
- Jaeger o Zipkin no estan implementados; se recomiendan para tracing distribuido entre microservicios.

## Lecciones sobre Docker Desktop y Kubernetes local

- Docker Desktop Kubernetes permite validar namespaces, pods, services y port-forward sin costo cloud.
- Algunos targets de Prometheus pueden aparecer `DOWN` porque Docker Desktop no expone todos los componentes del control plane como un cluster productivo.
- node-exporter puede entrar en `CrashLoopBackOff` por restricciones de mounts del host en Windows.
- Algunas rutas con espacios o formato Windows pueden afectar herramientas ejecutadas dentro de contenedores, como Trivy.
- Las limitaciones locales deben documentarse para que no se confundan con fallos de arquitectura.

Evidencias relacionadas:

- `evidence/05-observability/observability-notes.txt`
- `evidence/05-observability/node-exporter-describe.txt`
- `evidence/04-security/trivy-notes.txt`

## Recomendaciones para una futura version

### Observabilidad

- Implementar ELK Stack o una alternativa equivalente para logs centralizados.
- Implementar Jaeger o Zipkin para tracing distribuido.
- Crear dashboards Grafana por microservicio: auth, identity, form, promotion, notification, gateway, dashboard y file.
- Agregar alertas Prometheus especificas para errores 5xx, latencia alta, pods no disponibles y consumo de memoria.

### Seguridad

- Implementar TLS real para servicios expuestos publicamente mediante Ingress y certificados.
- Implementar RBAC Kubernetes con ServiceAccounts, Roles y RoleBindings por namespace.
- Sustituir secretos estaticos por External Secrets, Sealed Secrets o un gestor cloud.
- Integrar Trivy completamente en pipeline con evidencia versionada.
- Mantener OWASP ZAP como gate antes de produccion.

### CI/CD

- Configurar SonarQube con token real y guardar evidencia del Quality Gate.
- Evitar que controles criticos se omitan en master por falta de herramientas.
- Publicar tags semanticos reales y conservar evidencia de releases.
- Archivar reportes JaCoCo, ZAP, Trivy y Newman como artifacts del pipeline.

### Infraestructura

- Validar Terraform con `terraform validate` y guardar evidencia de `plan/apply`.
- Agregar probes readiness/liveness en todos los deployments.
- Definir requests/limits por servicio y ambiente.
- Preparar un despliegue cloud minimo separado del entorno academico local.

### Gestion del proyecto

- Versionar evidencia del tablero agil o exportar capturas de GitHub Projects/Jira/Trello.
- Mantener una bitacora de cambios con responsable, fecha, impacto y resultado.
- Documentar retrospectivas por sprint y decisiones tecnicas relevantes.

## Conclusion

CircleGuard logro una base tecnica amplia para un proyecto academico de Ingenieria de Software V: microservicios, mobile, CI/CD, IaC, pruebas, seguridad basica, observabilidad y release notes. Las mejoras prioritarias para una version futura son formalizar evidencias, endurecer seguridad productiva, completar observabilidad distribuida y convertir los controles condicionales de CI/CD en gates obligatorios para produccion.
