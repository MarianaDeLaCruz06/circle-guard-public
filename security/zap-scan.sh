#!/bin/bash
# -----------------------------------------------------------------------------
# Script de automatización de OWASP ZAP para CircleGuard.
# Ejecuta un escaneo básico de seguridad contra la API Gateway usando Docker.
# -----------------------------------------------------------------------------

TARGET_URL=${1:-"http://localhost:8087"}
REPORT_DIR="$(pwd)/security/reports"

# Crear directorio de reportes si no existe
mkdir -p "$REPORT_DIR"

echo "========================================================================"
echo "🛡️  Iniciando escaneo de seguridad OWASP ZAP contra: $TARGET_URL"
echo "========================================================================"

# Ejecutar el escaneo usando el contenedor oficial
# Usamos el script predefinido zap-baseline.py para un escaneo pasivo rápido y seguro
docker run --rm \
  -v "$REPORT_DIR:/zap/wrk/:rw" \
  -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t "$TARGET_URL" -r zap_report.html

# Verificar resultado
if [ $? -eq 0 ]; then
  echo "========================================================================"
  echo "✅ Escaneo completado. Reporte generado en: security/reports/zap_report.html"
  echo "========================================================================"
else
  echo "========================================================================"
  echo "⚠️  El escaneo finalizó con advertencias/alertas encontradas."
  echo "Revisa el reporte en: security/reports/zap_report.html"
  echo "========================================================================"
fi
