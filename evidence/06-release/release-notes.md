# Release Notes - CircleGuard Final Delivery

## Version
v1.0.0-final

## Summary
This release consolidates the final DevOps delivery for CircleGuard, including build validation, automated tests, Kubernetes deployment evidence, security scanning, and observability evidence.

## Main changes
- Added dashboard-service and file-service to the delivery pipeline.
- Added Dockerfiles for the required backend services.
- Updated Jenkins pipeline configuration.
- Updated Kubernetes manifests for the complete service set.
- Updated Terraform modules for the complete infrastructure definition.
- Added backend build evidence.
- Added backend, mobile and notification-service test evidence.
- Added OWASP ZAP baseline security scan evidence.
- Added Trivy filesystem scan evidence or scan execution notes.
- Added Actuator health and Prometheus metrics configuration.
- Added Prometheus and Grafana observability evidence.
- Documented Docker Desktop Kubernetes observability limitations.

## Security evidence
- OWASP ZAP baseline scan generated an HTML report.
- ZAP scan completed with no new failures.
- Trivy was executed using Docker or documented as a local execution limitation.

## Observability evidence
- Prometheus and Grafana were deployed using kube-prometheus-stack.
- Prometheus successfully scraped several targets.
- Grafana was available through port-forwarding.
- Some internal Kubernetes targets appeared DOWN due to Docker Desktop limitations, documented separately.

## Known limitations
- Some Prometheus targets are DOWN in Docker Desktop Kubernetes because local control plane endpoints are not exposed like in a production Kubernetes cluster.
- node-exporter appears in CrashLoopBackOff due to Docker Desktop host mount and permission constraints.
- LDAP health check reports DOWN in local execution because LDAP is not running locally.
