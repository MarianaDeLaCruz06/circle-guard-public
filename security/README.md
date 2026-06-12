# Pruebas de Seguridad con OWASP ZAP — CircleGuard

> Documento del **Requisito 5 — Pruebas de Seguridad** del Proyecto Final.

Este directorio contiene las herramientas y documentación necesarias para realizar análisis y auditorías de seguridad sobre las APIs del Gateway de CircleGuard utilizando el escáner de vulnerabilidades de **OWASP Zed Attack Proxy (ZAP)**.

---

## 1. ¿Qué es OWASP ZAP?

**OWASP ZAP** es una herramienta de seguridad de código abierto ampliamente utilizada para realizar escaneos pasivos y activos de vulnerabilidades en aplicaciones web y APIs. Se enfoca en detectar riesgos comunes de seguridad listados en el **OWASP Top 10**, tales como:
- Divulgación de información sensible (Information Disclosure).
- Cabeceras de seguridad HTTP faltantes o incorrectas (X-Content-Type-Options, CSP, etc.).
- Vulnerabilidades de inyección de código (SQL Injection, Cross-Site Scripting - XSS).
- Configuraciones de SSL/TLS deficientes.
- Fugas de rutas o versiones de servidor expuestas.

---

## 2. Prerrequisitos

Para ejecutar las pruebas de seguridad sin necesidad de instalar el cliente de escritorio de ZAP, utilizamos el contenedor oficial de Docker:
- Tener **Docker Desktop** (o Docker Engine) instalado y corriendo en tu máquina.
- Tener las APIs del microservicio Gateway (`circleguard-gateway-service`) arriba (por defecto en `http://localhost:8087`).

---

## 3. Instrucciones de Ejecución

Hemos creado scripts automatizados para simplificar la ejecución tanto en sistemas basados en UNIX como en Windows.

### En Linux o macOS:
1. Asegúrate de dar permisos de ejecución al script:
   ```bash
   chmod +x security/zap-scan.sh
   ```
2. Ejecuta el script contra el endpoint del Gateway (por defecto `http://localhost:8087`):
   ```bash
   ./security/zap-scan.sh
   ```
   *Nota: Puedes pasar un endpoint alternativo como argumento:*
   ```bash
   ./security/zap-scan.sh http://localhost:8080
   ```

### En Windows (PowerShell o CMD):
1. Abre tu terminal en la raíz del proyecto.
2. Ejecuta el archivo por lotes (batch script):
   ```cmd
   security\zap-scan.bat
   ```
   *O especificando el host:*
   ```cmd
   security\zap-scan.bat http://localhost:8080
   ```

---

## 4. Reportes de Vulnerabilidades

El script monta un volumen Docker local apuntando a `security/reports/`. Una vez finalizado el escaneo, se generará el siguiente archivo:
*   [Reporte HTML de Vulnerabilidades ZAP](circle-guard-public/security/reports/zap_report.html)
    *(Abre este reporte en tu navegador web para visualizar el resumen de alertas clasificadas por severidad: Alta, Media, Baja e Informativa).*

---

## 5. Escaneo Avanzado con Rúbrica OpenAPI

Dado que cada microservicio de CircleGuard expone su documentación OpenAPI (Swagger), es posible indicarle a OWASP ZAP que parsee la rúbrica OpenAPI para descubrir endpoints específicos y realizar un escaneo activo sobre ellos.

Ejemplo de ejecución con OpenAPI:
```bash
docker run --rm \
  -v "$(pwd)/security/reports:/zap/wrk/:rw" \
  -t ghcr.io/zaproxy/zaproxy:stable \
  zap-api-scan.py -t "http://localhost:8087/v3/api-docs" -f openapi -r zap_report_openapi.html
```
*Este comando descarga la especificación de OpenAPI expuesta por el Gateway y analiza pasiva y activamente cada endpoint listado.*
