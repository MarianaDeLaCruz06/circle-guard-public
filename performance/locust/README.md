# CircleGuard Locust Performance Tests

This folder contains the Locust load test used for the DevOps workshop.
The test exercises five backend endpoints from the local CircleGuard
microservices:

- `POST /api/v1/auth/visitor/handoff`
- `GET /api/v1/questionnaires`
- `POST /api/v1/surveys`
- `POST /api/v1/gate/validate`
- `GET /api/v1/health-status/stats`

## Run locally

```bash
locust -f performance/locust/locustfile.py
```

## Headless execution

Command used for the workshop evidence:

```bash
FORM_URL=http://localhost:8086 locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --html performance/locust/report.html
```

Parameters:

- `-u 20`: simulates 20 concurrent users.
- `-r 5`: ramps up 5 users per second.
- `-t 2m`: runs the test for 2 minutes.
- `--host http://localhost:8180`: base Locust host. The test also uses full URLs for the other services.
- `--html performance/locust/report.html`: generates an HTML report.

## Local service URLs

The test uses these default URLs:

- Auth: `http://localhost:8180`
- Form: `http://localhost:8086`
- Gateway: `http://localhost:8087`
- Promotion: `http://localhost:8088`

They can be overridden with environment variables:

- `AUTH_URL`
- `FORM_URL`
- `PROMOTION_URL`
- `GATEWAY_URL`
- `ANONYMOUS_ID`

## Result summary

Execution date: `2026-05-02`

Command:

```bash
locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --host http://localhost:8180 --html performance/locust/report.html
```

Observed result during the run:

| Metric | Value |
| --- | --- |
| Concurrent users | 20 |
| Ramp-up | 5 users/second |
| Duration | 2 minutes |
| Error rate | 0.00% |
| Peak observed throughput | Around 10 req/s |
| Aggregated average response time | Around 12-13 ms |
| Fastest observed response | 2 ms |
| Slowest observed response | 43 ms |

Endpoint-level observations from the console output:

| Endpoint | Result | Average response time observed |
| --- | --- | --- |
| `GET /api/v1/health-status/stats` | 0 failures | Around 17-19 ms |
| `GET /api/v1/questionnaires` | 0 failures | Around 11-13 ms |
| `POST /api/v1/auth/visitor/handoff` | 0 failures | Around 7-9 ms |
| `POST /api/v1/gate/validate` | 0 failures | Around 7-9 ms |
| `POST /api/v1/surveys` | 0 failures | Around 18-20 ms |

## Analysis

The load test completed successfully with 20 concurrent users and no HTTP
failures in the sampled output. The application handled a small academic
workload with stable latency: the aggregated average response time remained
close to 12-13 ms and the maximum observed response time stayed below 50 ms.

The throughput stabilized around 9-10 requests per second while the users were
active. This is acceptable for the workshop scenario because the goal is to
demonstrate performance testing coverage, not to define a production capacity
limit.

The previous 404 issue in the questionnaire scenario was avoided by using the
real backend route `GET /api/v1/questionnaires`, which does not depend on the
existence of an active questionnaire record.
