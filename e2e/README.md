# CircleGuard E2E Tests

Run the Postman collection against services exposed on localhost:

```bash
npm install -g newman

newman run e2e/circleguard-e2e.postman_collection.json
```

The collection covers visitor handoff, active questionnaire lookup, survey submission,
gateway validation, and a basic health-status endpoint smoke test.
