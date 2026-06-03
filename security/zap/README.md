# OWASP ZAP Baseline

This folder contains the minimal security baseline scan for CircleGuard.

## Prerequisites

- Docker Desktop running.
- At least one CircleGuard service reachable from Docker.
- For local Windows execution, use `host.docker.internal` instead of `localhost`.

## Run baseline scan

Default target is the auth service on port `8180`:

```powershell
.\security\zap\zap-baseline.ps1
```

Custom target:

```powershell
.\security\zap\zap-baseline.ps1 -TargetUrl "http://host.docker.internal:8084"
```

The HTML report is written to:

```text
evidence/04-security/zap-baseline-report.html
```

## Trivy evidence commands

Filesystem scan:

```powershell
trivy fs --severity HIGH,CRITICAL --no-progress . *> evidence/04-security/trivy-fs-scan.txt
```

Dashboard image scan:

```powershell
trivy image --severity HIGH,CRITICAL --no-progress circleguard-dashboard-service:local *> evidence/04-security/trivy-dashboard-image.txt
```

File service image scan:

```powershell
trivy image --severity HIGH,CRITICAL --no-progress circleguard-file-service:local *> evidence/04-security/trivy-file-image.txt
```

If Trivy exits non-zero, keep the output file as evidence and document whether the finding is exploitable in this academic deployment.
