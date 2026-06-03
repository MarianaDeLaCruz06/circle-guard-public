param(
    [string]$TargetUrl = "http://host.docker.internal:8180",
    [string]$ReportPath = "evidence/04-security/zap-baseline-report.html"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$absoluteReportPath = Join-Path $repoRoot $ReportPath
$evidenceDir = Split-Path -Parent $absoluteReportPath

New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

$reportFile = Split-Path -Leaf $absoluteReportPath
$zapWorkDir = "/zap/wrk"
$dockerVolume = "${evidenceDir}:${zapWorkDir}:rw"

Write-Host "Running OWASP ZAP baseline scan"
Write-Host "Target: $TargetUrl"
Write-Host "Report: $absoluteReportPath"

docker run --rm -t `
    -v $dockerVolume `
    ghcr.io/zaproxy/zaproxy:stable `
    zap-baseline.py `
    -t $TargetUrl `
    -r $reportFile

if (-not (Test-Path $absoluteReportPath)) {
    throw "ZAP report was not created at $absoluteReportPath"
}

Write-Host "ZAP baseline report generated: $absoluteReportPath"
