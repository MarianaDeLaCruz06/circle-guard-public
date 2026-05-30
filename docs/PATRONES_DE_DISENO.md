# Patrones de Diseño en CircleGuard

> Documento del **Requisito 3 — Patrones de Diseño (10%)** del Proyecto Final IngeSoft V.

Este documento cataloga los patrones de diseño implementados en CircleGuard:
1. **Patrones preexistentes** ya presentes en la arquitectura.
2. **Patrones nuevos** introducidos en este entregable: Circuit Breaker, Retry y Feature Toggle.

---

## 1. Patrones preexistentes en la arquitectura

| # | Patrón | Categoría | Dónde está | Propósito |
|---|---|---|---|---|
| 1 | **Repository** | Persistencia | [`LocalUserRepository.java`](../services/circleguard-auth-service/src/main/java/com/circleguard/auth/repository/LocalUserRepository.java), [`HealthSurveyRepository.java`](../services/circleguard-form-service/src/main/java/com/circleguard/form/repository/HealthSurveyRepository.java), [`IdentityMappingRepository.java`](../services/circleguard-identity-service/src/main/java/com/circleguard/identity/repository/IdentityMappingRepository.java), [`UserNodeRepository.java`](../services/circleguard-promotion-service/src/main/java/com/circleguard/promotion/repository/graph/UserNodeRepository.java) | Abstrae acceso a datos. Permite cambiar el motor de persistencia (PostgreSQL ↔ Neo4j) sin tocar la capa de servicios. |
| 2 | **Chain of Responsibility** | Comportamiento | [`DualChainAuthenticationProvider.java`](../services/circleguard-auth-service/src/main/java/com/circleguard/auth/security/DualChainAuthenticationProvider.java) | Permite que múltiples proveedores de autenticación (LDAP + DB local) procesen la solicitud en cadena; el primero que la acepta termina el flujo. |
| 3 | **Strategy + Dispatcher** | Comportamiento | [`NotificationDispatcher.java`](../services/circleguard-notification-service/src/main/java/com/circleguard/notification/service/NotificationDispatcher.java) enrutando a `EmailService`, `SmsService`, `PushService` | Cada canal de notificación es una estrategia intercambiable. El dispatcher decide a cuáles invocar sin conocer su implementación interna. |
| 4 | **Observer (Event-Driven via Kafka)** | Comportamiento | [`ExposureNotificationListener.java`](../services/circleguard-notification-service/src/main/java/com/circleguard/notification/service/ExposureNotificationListener.java), [`SurveyListener.java`](../services/circleguard-promotion-service/src/main/java/com/circleguard/promotion/listener/SurveyListener.java), [`CircleFencedListener.java`](../services/circleguard-notification-service/src/main/java/com/circleguard/notification/service/CircleFencedListener.java), [`PriorityAlertListener.java`](../services/circleguard-notification-service/src/main/java/com/circleguard/notification/service/PriorityAlertListener.java) | Desacopla productores y consumidores de eventos. Cada listener reacciona a tópicos Kafka sin que el publicador los conozca. |
| 5 | **Data Transfer Object (DTO)** | Estructural | [`AccessPointDTO.java`](../services/circleguard-promotion-service/src/main/java/com/circleguard/promotion/dto/AccessPointDTO.java), [`BuildingDTO.java`](../services/circleguard-promotion-service/src/main/java/com/circleguard/promotion/dto/BuildingDTO.java), [`FloorDTO.java`](../services/circleguard-promotion-service/src/main/java/com/circleguard/promotion/dto/FloorDTO.java) | Aísla los modelos del dominio (Neo4j/JPA) del contrato HTTP público. Evita exponer columnas internas. |
| 6 | **Filter Chain** | Estructural | [`JwtAuthenticationFilter.java`](../services/circleguard-auth-service/src/main/java/com/circleguard/auth/security/JwtAuthenticationFilter.java), [`JwtAuthenticationFilter.java`](../services/circleguard-identity-service/src/main/java/com/circleguard/identity/config/JwtAuthenticationFilter.java) | Aplica autenticación y autorización a cada request antes de que llegue al controlador. |
| 7 | **Converter / Encryptor** | Estructural | [`IdentityEncryptionConverter.java`](../services/circleguard-identity-service/src/main/java/com/circleguard/identity/util/IdentityEncryptionConverter.java) | Encripta/desencripta el campo `realIdentity` de forma transparente al persistir. Cumple FERPA. |
| 8 | **API Gateway** | Estructural | [`circleguard-gateway-service`](../services/circleguard-gateway-service/) | Punto de entrada unificado a todos los microservicios; concentra validación QR y enrutamiento. |

---

## 2. Patrones nuevos implementados

### 2.1 Circuit Breaker (resiliencia)

**Implementación:** Resilience4j 2.2.0 con anotaciones declarativas.

**Dónde:**
- [`IdentityClient.java`](../services/circleguard-auth-service/src/main/java/com/circleguard/auth/client/IdentityClient.java) — llamadas `auth-service → identity-service`
- [`PromotionClient.java`](../services/circleguard-dashboard-service/src/main/java/com/circleguard/dashboard/client/PromotionClient.java) — llamadas `dashboard-service → promotion-service`

**Configuración** (en cada `application.yml`):
```yaml
resilience4j:
  circuitbreaker:
    instances:
      identityService:                       # o promotionService
        slidingWindowType: COUNT_BASED
        slidingWindowSize: 10                # mide sobre las últimas 10 llamadas
        minimumNumberOfCalls: 5              # no abre antes de 5 muestras
        failureRateThreshold: 50             # si 50%+ fallan → abre
        waitDurationInOpenState: 10s         # 10s en OPEN antes de probar
        permittedNumberOfCallsInHalfOpenState: 3
        automaticTransitionFromOpenToHalfOpenEnabled: true
```

**Propósito:** Cuando el servicio dependiente (identity/promotion) falla repetidamente, el breaker se abre y deja de propagar la llamada. Esto evita:
- Cascading failures (un servicio caído tumbando a todos los demás).
- Saturación de threads/sockets esperando respuestas que nunca llegan.
- Sobrecarga al servicio caído cuando ya está en problemas.

**Beneficios:**
- ✅ **Fail fast:** la llamada retorna en microsegundos cuando el breaker está abierto, en lugar de timeout de 30s.
- ✅ **Auto-healing:** después de `waitDurationInOpenState`, prueba con tráfico limitado (HALF_OPEN) y se cierra solo cuando el servicio dependiente vuelve.
- ✅ **Fallback degradado:** ambos clients tienen método `*Fallback` que retorna respuesta funcional (UUID determinista en auth, payload `degraded=true` en dashboard) en vez de excepción.
- ✅ **Observabilidad gratis:** estado expuesto en `/actuator/health` y `/actuator/circuitbreakers`.

### 2.2 Retry con backoff exponencial (resiliencia complementaria)

**Implementación:** Resilience4j 2.2.0, anotación `@Retry`.

**Dónde:** Mismos métodos que el Circuit Breaker — se ejecuta **antes** que el CB.

**Configuración:**
```yaml
resilience4j:
  retry:
    instances:
      identityService:
        maxAttempts: 3
        waitDuration: 500ms
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2     # 500ms → 1s → 2s
```

**Propósito:** Reintentar errores transitorios (DNS hiccup, TCP reset, GC pause) antes de declarar al servicio como caído.

**Beneficios:**
- ✅ **Resiliencia a fallos transitorios:** un blip de red de 100ms ya no provoca error visible al usuario.
- ✅ **Backoff exponencial:** evita martillar al servicio remoto si ya está sobrecargado.
- ✅ **Composición con Circuit Breaker:** si las 3 reintentos fallan, contribuyen al ratio del breaker → eventualmente se abre.

**Composición Retry + Circuit Breaker:**
```
Request → @Retry (3 intentos con backoff)
            └─ si todos fallan → cuenta como 1 falla del CB
                                 └─ @CircuitBreaker abre tras 50% fallas en 10 calls
                                    └─ fallback retorna respuesta degradada
```

### 2.3 Feature Toggle (configuración externa)

**Implementación:** Spring Boot `@ConfigurationProperties` leyendo de `application.yml` / variables de entorno (inyectadas por el ConfigMap de Kubernetes).

**Dónde:**
- [`FeatureToggleProperties.java`](../services/circleguard-notification-service/src/main/java/com/circleguard/notification/config/FeatureToggleProperties.java) — define los toggles
- [`NotificationDispatcher.java`](../services/circleguard-notification-service/src/main/java/com/circleguard/notification/service/NotificationDispatcher.java) — los consume antes de cada canal

**Configuración:**
```yaml
circleguard:
  features:
    notifications:
      email:
        enabled: ${CIRCLEGUARD_FEATURES_EMAIL_ENABLED:true}
      sms:
        enabled: ${CIRCLEGUARD_FEATURES_SMS_ENABLED:true}
      push:
        enabled: ${CIRCLEGUARD_FEATURES_PUSH_ENABLED:true}
```

**Propósito:** Habilitar/deshabilitar canales de notificación sin redeploy.

**Casos de uso reales:**
- ✋ El proveedor SMS (Twilio) está caído → `kubectl set env deployment/circleguard-notification-service CIRCLEGUARD_FEATURES_SMS_ENABLED=false` y dejamos solo email/push.
- 💰 Reducir costos en horario nocturno (push gratis, SMS cuesta).
- 🧪 Canary: habilitar push solo en namespace stage.
- 🚨 Apagar email cuando llega un pico de bounces para evitar manchar la reputación del dominio.

**Beneficios:**
- ✅ **Cambios sin redeploy:** un `kubectl set env` aplica al pod sin rebuild de imagen.
- ✅ **Failsafe:** si el canal se desactiva, el sistema sigue notificando por los demás (en vez de fallar completo).
- ✅ **Defaults seguros:** todos los toggles default a `true` — desactivar es una decisión explícita.
- ✅ **Auditabilidad:** el cambio queda en el historial del ConfigMap/Deployment.

---

## 3. Cómo verificar los patrones nuevos en runtime

### Circuit Breaker
```bash
# Ver estado del breaker
curl http://localhost:8180/actuator/circuitbreakers
curl http://localhost:8084/actuator/circuitbreakers

# Simular caída de identity-service y observar transición CLOSED → OPEN
kubectl scale deployment/circleguard-identity-service --replicas=0 -n circleguard-dev
# hacer 10 requests a auth → el breaker debería abrir
```

### Feature Toggle
```bash
# Desactivar SMS en runtime (sin redeploy)
kubectl set env deployment/circleguard-notification-service \
  CIRCLEGUARD_FEATURES_SMS_ENABLED=false \
  -n circleguard-dev

# Verificar logs — debería aparecer "SMS channel disabled by feature toggle"
kubectl logs -f deployment/circleguard-notification-service -n circleguard-dev
```

---

## 4. Tradeoffs y decisiones

| Decisión | Alternativa descartada | Razón |
|---|---|---|
| Resilience4j sobre Spring Retry | Spring Retry solo | Spring Retry no tiene Circuit Breaker — y el documento del proyecto lo pide explícitamente como ejemplo de resiliencia. |
| Anotaciones declarativas (`@CircuitBreaker`) | API programática (`CircuitBreakerRegistry`) | Menos boilerplate; la configuración vive en YAML, no en código. |
| Feature Toggle vía `@ConfigurationProperties` | LaunchDarkly / Unleash | Una librería SaaS sería overkill para un proyecto académico; el ConfigMap de K8s ya es un sistema de configuración externo. |
| Toggles default `true` | Default `false` | "Opt-out" en vez de "opt-in" — desactivar es una decisión consciente, no un olvido. |
| 3 patrones nuevos | Más | El documento pide "al menos 3" — agregar más sin necesidad de negocio sería over-engineering. |

---

## 5. Cumplimiento del Req. 3

| Subitem del documento | Estado |
|---|---|
| Identificar y documentar patrones existentes | ✅ 8 patrones catalogados con archivo:línea |
| Implementar patrón de resiliencia | ✅ Circuit Breaker (Resilience4j) + Retry con backoff |
| Implementar patrón de configuración | ✅ Feature Toggle vía `@ConfigurationProperties` + env vars |
| Implementar al menos 3 patrones adicionales | ✅ Circuit Breaker + Retry + Feature Toggle |
| Documentar propósito y beneficios | ✅ Este documento |
