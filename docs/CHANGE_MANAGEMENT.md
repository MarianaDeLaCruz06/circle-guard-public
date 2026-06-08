# Change Management — CircleGuard

> Documento del **Requisito 6 — Change Management y Release Notes** del Proyecto Final IngeSoft V.

Este documento define el proceso formal para introducir, evaluar, aprobar, ejecutar y reversar cambios en cualquier ambiente del sistema CircleGuard (dev → stage → master).

---

## 1. Objetivos

| Objetivo | Cómo lo aseguramos |
|---|---|
| Ningún cambio llega a producción sin trazabilidad. | Toda modificación pasa por un PR vinculado a un Change Request (CR) y al final queda en las Release Notes generadas por `Jenkinsfile.master`. |
| Cambios riesgosos requieren aprobación humana. | El stage **`Approval to Deploy Production`** en `Jenkinsfile.master` exige click manual de un aprobador autorizado. |
| Cualquier cambio puede ser revertido. | Para cada componente existe un procedimiento de rollback en [`ROLLBACK_PLAYBOOK.md`](ROLLBACK_PLAYBOOK.md). |
| El equipo conoce el estado del sistema en tiempo real. | Etiquetas semánticas (`vX.Y.Z`) publicadas en git por el pipeline + dashboard Grafana con métricas de la versión desplegada. |

---

## 2. Clasificación de cambios

Adaptamos las tres categorías estándar de ITIL:

| Tipo | Criterio | Ejemplos | Aprobación | Ventana |
|---|---|---|---|---|
| **Standard** | Cambio pre-aprobado, bajo riesgo, repetible. | Bump de patch version, ajuste de feature toggle, refresco de imagen sin cambios funcionales. | Aprobación implícita del CAB (definida en este documento). | Cualquier momento. |
| **Normal** | Cambio que requiere evaluación caso a caso. | Feature nuevo, cambio de configuración crítica, alteración de DB, nueva dependencia, cambio de Dockerfile. | CAB (Change Advisory Board) → quórum de 2/3. | Lunes a viernes 9 am – 4 pm. |
| **Emergency** | Cambio para resolver un incidente activo o vulnerabilidad zero-day. | Fix de CVE crítico encontrado por Trivy, rollback urgente, mitigación de fuga de datos. | 1 miembro CAB + post-mortem obligatorio. | Cualquier momento (24/7). |

> **Regla práctica**: si dudas si tu cambio es Standard o Normal, trátalo como Normal.

---

## 3. RACI

| Actividad | PO (Valentina) | SM (Mariana) | Dev/DevOps Lead (Alexis) | CAB |
|---|:---:|:---:|:---:|:---:|
| Crear Change Request | C | C | **R** | I |
| Evaluar impacto técnico | I | I | **R** | C |
| Evaluar impacto de negocio | **R** | I | C | C |
| Aprobar cambio Normal | C | I | C | **A** |
| Aprobar Emergency | I | C | **A** | I |
| Ejecutar cambio en stage | I | C | **R** | I |
| Aprobar despliegue a master | **A** | C | C | C |
| Ejecutar rollback | I | **A** | **R** | I |
| Validar post-deploy | C | C | **R** | I |

**Leyenda:** R = Responsable, A = Aprobador, C = Consultado, I = Informado.

**Composición del CAB:** PO + SM + Dev/DevOps Lead. Sesiona los lunes 10 am o ad-hoc para Emergency.

---

## 4. Flujo del proceso

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   1. Identificar necesidad de cambio                                         │
│           │                                                                  │
│           ▼                                                                  │
│   2. Crear Change Request (CR) usando la plantilla                           │
│      change-management/CHANGE_REQUEST_TEMPLATE.md                            │
│           │                                                                  │
│           ▼                                                                  │
│   3. Clasificar (Standard / Normal / Emergency)                              │
│           │                                                                  │
│           ▼                                                                  │
│   4. Implementar en rama feature/* → PR a dev                                │
│      ✓ Tests unitarios + integración                                         │
│      ✓ Jenkinsfile.dev verde (SonarQube + Trivy + Smoke)                     │
│           │                                                                  │
│           ▼                                                                  │
│   5. Merge a stage → Jenkinsfile.stage verde                                 │
│      ✓ Integration Tests + OWASP ZAP advisory                                │
│           │                                                                  │
│           ▼                                                                  │
│   6. CAB review (Normal) — aprueba o rechaza                                 │
│           │                                                                  │
│           ▼                                                                  │
│   7. Merge a master → Jenkinsfile.master                                     │
│      ✓ Trivy gate (HIGH/CRITICAL bloquean)                                   │
│      ✓ ZAP gate (UNSTABLE bloquea aprobación)                                │
│      ✓ Approval to Deploy Production (click manual)                          │
│           │                                                                  │
│           ▼                                                                  │
│   8. Deploy + Smoke Tests + Release Notes + Git Tag                          │
│           │                                                                  │
│           ▼                                                                  │
│   9. Post-deploy validation (dashboards Grafana + ZAP en producción)         │
│           │                                                                  │
│           ▼                                                                  │
│  10. Si falla → ejecutar ROLLBACK_PLAYBOOK.md                                │
│      Si pasa  → cerrar CR como Done                                          │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Trazabilidad

Cada cambio debe poder responderse a estas 5 preguntas en menos de 1 minuto:

| Pregunta | Dónde se encuentra |
|---|---|
| ¿Qué cambió? | Commits del PR + Release Notes (`release-notes.md` archivado por `Jenkinsfile.master`) |
| ¿Por qué? | Descripción del CR + descripción del PR |
| ¿Quién aprobó? | Reviewers del PR + `APPROVED_BY` en logs del Jenkins build (variable capturada en el stage `Approval to Deploy Production`) |
| ¿Cuándo se desplegó? | Build number Jenkins + git tag `vX.Y.Z` + timestamp del commit del tag |
| ¿Cómo revertirlo? | [`ROLLBACK_PLAYBOOK.md`](ROLLBACK_PLAYBOOK.md) con runbook por componente |

---

## 6. Sistema de etiquetado de releases

Implementado en [`jenkins/shared.groovy`](../jenkins/shared.groovy) → función `computeVersion(channel)`:

| Canal | Esquema | Ejemplo | Persistencia git |
|---|---|---|---|
| `dev` | `0.0.0-dev.<shortSha>` | `0.0.0-dev.a1b2c3d` | No (snapshot efímero). |
| `stage` | `<lastTag>-rc.<buildNumber>` | `v1.2.3-rc.47` | No (etiquetado solo en la imagen Docker). |
| `master` | `<lastTag>` con `patch+1` | `1.2.4` | **Sí**, si el operador activa `CREATE_GIT_TAG=true` al lanzar el build. La función `tagGitRelease()` ejecuta `git tag -a vX.Y.Z` + `git push origin`. |

Esto garantiza que cada release productivo queda inmortalizado en el repositorio como un tag navegable, vinculado al commit exacto que se desplegó.

---

## 7. Plantillas

- [`change-management/CHANGE_REQUEST_TEMPLATE.md`](../change-management/CHANGE_REQUEST_TEMPLATE.md) — plantilla a copiar como descripción del PR o issue.

---

## 8. Cumplimiento del Req. 6

| Subitem del documento | Estado | Implementación |
|---|---|---|
| Definir un proceso formal de Change Management | ✅ | Este documento (clasificación + RACI + flujo) |
| Implementar generación automática de Release Notes | ✅ | `Jenkinsfile.master` stage `Generate Release Notes` + `shared.groovy → generateReleaseNotes()` |
| Documentar planes de rollback | ✅ | [`ROLLBACK_PLAYBOOK.md`](ROLLBACK_PLAYBOOK.md) + scripts en `scripts/rollback-*.{sh,ps1}` |
| Implementar sistema de etiquetado de releases | ✅ | `computeVersion(channel)` + `tagGitRelease()` con param `CREATE_GIT_TAG` |
