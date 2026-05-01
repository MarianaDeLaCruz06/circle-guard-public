# CircleGuard Locust Performance Tests

Run locally:

```bash
locust -f performance/locust/locustfile.py
```

Headless example:

```bash
locust -f performance/locust/locustfile.py --headless -u 20 -r 5 -t 2m --html performance/locust/report.html
```

Configurable environment variables:

- `AUTH_URL`
- `FORM_URL`
- `PROMOTION_URL`
- `GATEWAY_URL`
- `ANONYMOUS_ID`
