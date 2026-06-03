@echo off
:: -----------------------------------------------------------------------------
:: Script de automatización de OWASP ZAP para CircleGuard (Windows CMD).
:: -----------------------------------------------------------------------------

set TARGET_URL=%1
if "%TARGET_URL%"=="" set TARGET_URL=http://localhost:8087
set REPORT_DIR=%cd%\security\reports

if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"

echo ========================================================================
echo 🛡️  Iniciando escaneo de seguridad OWASP ZAP contra: %TARGET_URL%
echo ========================================================================

docker run --rm ^
  -v "%REPORT_DIR%:/zap/wrk/:rw" ^
  -t ghcr.io/zaproxy/zaproxy:stable ^
  zap-baseline.py -t %TARGET_URL% -r zap_report.html

echo ========================================================================
echo ✅ Escaneo completado. Reporte generado en: security\reports\zap_report.html
echo ========================================================================
