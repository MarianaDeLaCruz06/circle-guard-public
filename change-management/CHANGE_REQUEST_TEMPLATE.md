# Change Request — CR-<NÚMERO>

> Copia este archivo como **descripción del PR** o como issue en GitHub.
> Vincúlalo al pipeline Jenkins correspondiente.

---

## Metadata

| Campo | Valor |
|---|---|
| **CR ID** | CR-YYYY-MM-DD-### |
| **Título** | (resumen en 1 línea) |
| **Solicitante** | @usuario |
| **Fecha de creación** | YYYY-MM-DD |
| **Tipo** | ☐ Standard ☐ Normal ☐ Emergency |
| **Prioridad** | ☐ Baja ☐ Media ☐ Alta ☐ Crítica |
| **Ambientes afectados** | ☐ dev ☐ stage ☐ master |
| **Servicios afectados** | (listar microservicios) |

---

## 1. Descripción del cambio

(¿Qué se modifica? ¿Por qué? Vincular a issue/historia de usuario.)

## 2. Justificación de negocio

(¿Qué problema resuelve o qué valor agrega?)

## 3. Análisis de impacto

| Componente | Tipo de impacto | Detalle |
|---|---|---|
| Código (microservicio X) | (alto/medio/bajo) | |
| Configuración (ConfigMap/Secret) | | |
| Schema DB | | |
| Infraestructura (Terraform) | | |
| Contratos API públicos | | (¿breaking change?) |
| Performance esperada | | |

## 4. Plan de pruebas

- [ ] Tests unitarios (`./gradlew test`) pasan localmente.
- [ ] Tests de integración (`./gradlew integrationTest`) pasan localmente.
- [ ] Pipeline `Jenkinsfile.dev` verde.
- [ ] Pipeline `Jenkinsfile.stage` verde (incluye ZAP advisory).
- [ ] Coverage no decreció (JaCoCo).
- [ ] (Opcional) Pruebas de carga Locust si el endpoint es crítico.

## 5. Plan de rollback

**Estrategia primaria:** (Sección X de [`ROLLBACK_PLAYBOOK.md`](../docs/ROLLBACK_PLAYBOOK.md))

**Comandos de rollback:**
```bash
# (copiar el comando exacto que se ejecutaría)
./scripts/rollback-k8s.sh circleguard-master circleguard-<servicio>-service
```

**Tiempo estimado de rollback:** < N minutos.

**¿Requiere coordinación con DB / equipo externo?** Sí/No (explicar)

## 6. Aprobaciones

| Rol | Persona | Estado | Fecha |
|---|---|---|---|
| Reviewer PR (Dev) | @ | ☐ Pendiente ☐ Aprobado ☐ Rechazado | |
| CAB Member 1 (PO) | @valentina | | |
| CAB Member 2 (SM) | @mariana | | |
| CAB Member 3 (Lead) | @alexis | | |
| Approver despliegue prod (Jenkins) | | | |

## 7. Ventana de despliegue planeada

- **Fecha:** YYYY-MM-DD
- **Hora inicio (UTC-5):** HH:MM
- **Duración estimada:** N min
- **¿Requiere ventana de mantenimiento?** Sí/No

## 8. Comunicación

- ☐ Notificar al equipo en Slack #circleguard-releases antes del deploy.
- ☐ Actualizar el dashboard de estado interno.
- ☐ (Si breaking change) notificar a usuarios consumidores con 48h de anticipación.

## 9. Post-deploy

- [ ] Smoke Tests del pipeline pasaron.
- [ ] Dashboards Grafana sin anomalías por > 15 min.
- [ ] Release Notes generadas y archivadas en Jenkins.
- [ ] Git tag `vX.Y.Z` publicado.
- [ ] CR cerrado como **Done**.

---

> Después de cerrar este CR, el cambio queda trazable en:
> 1. Este documento (vinculado al PR).
> 2. `release-notes.md` archivado por `Jenkinsfile.master`.
> 3. El git tag `vX.Y.Z` que apunta al commit exacto desplegado.
