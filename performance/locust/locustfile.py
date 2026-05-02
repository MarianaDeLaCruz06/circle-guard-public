import os

from locust import HttpUser, between, task


AUTH_URL = os.getenv("AUTH_URL", "http://localhost:8180")
FORM_URL = os.getenv("FORM_URL", "http://localhost:8086")
PROMOTION_URL = os.getenv("PROMOTION_URL", "http://localhost:8088")
GATEWAY_URL = os.getenv("GATEWAY_URL", "http://localhost:8087")
ANONYMOUS_ID = os.getenv("ANONYMOUS_ID", "550e8400-e29b-41d4-a716-446655440000")

AUTH_VISITOR_HANDOFF = "/api/v1/auth/visitor/handoff"
FORM_QUESTIONNAIRES = "/api/v1/questionnaires"
FORM_SURVEYS = "/api/v1/surveys"
GATE_VALIDATE = "/api/v1/gate/validate"
PROMOTION_HEALTH_STATS = "/api/v1/health-status/stats"


class CircleGuardUser(HttpUser):
    host = os.getenv("LOCUST_HOST", "http://localhost")
    wait_time = between(1, 3)

    def _check_response(self, response, expected_status=200):
        if response.status_code != expected_status:
            response.failure(
                f"Expected HTTP {expected_status}, got HTTP {response.status_code}: {response.text[:200]}"
            )

    @task
    def visitor_handoff(self):
        with self.client.post(
            f"{AUTH_URL}{AUTH_VISITOR_HANDOFF}",
            json={"anonymousId": ANONYMOUS_ID},
            name=f"POST {AUTH_VISITOR_HANDOFF}",
            catch_response=True,
        ) as response:
            self._check_response(response)

    @task
    def list_questionnaires(self):
        with self.client.get(
            f"{FORM_URL}{FORM_QUESTIONNAIRES}",
            name=f"GET {FORM_QUESTIONNAIRES}",
            catch_response=True,
        ) as response:
            self._check_response(response)

    @task
    def submit_survey(self):
        with self.client.post(
            f"{FORM_URL}{FORM_SURVEYS}",
            json={
                "anonymousId": ANONYMOUS_ID,
                "hasFever": True,
                "hasCough": True,
                "otherSymptoms": "locust load test",
            },
            name=f"POST {FORM_SURVEYS}",
            catch_response=True,
        ) as response:
            self._check_response(response)

    @task
    def validate_gateway(self):
        with self.client.post(
            f"{GATEWAY_URL}{GATE_VALIDATE}",
            json={"token": "invalid-demo-token"},
            name=f"POST {GATE_VALIDATE}",
            catch_response=True,
        ) as response:
            self._check_response(response)

    @task
    def health_status_stats(self):
        with self.client.get(
            f"{PROMOTION_URL}{PROMOTION_HEALTH_STATS}",
            name=f"GET {PROMOTION_HEALTH_STATS}",
            catch_response=True,
        ) as response:
            self._check_response(response)
