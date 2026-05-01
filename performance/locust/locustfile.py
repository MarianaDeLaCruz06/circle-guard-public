import os
from locust import HttpUser, between, task


AUTH_URL = os.getenv("AUTH_URL", "http://localhost:8180")
FORM_URL = os.getenv("FORM_URL", "http://localhost:8086")
PROMOTION_URL = os.getenv("PROMOTION_URL", "http://localhost:8088")
GATEWAY_URL = os.getenv("GATEWAY_URL", "http://localhost:8087")
ANONYMOUS_ID = os.getenv("ANONYMOUS_ID", "550e8400-e29b-41d4-a716-446655440000")


class CircleGuardUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def visitor_handoff(self):
        self.client.post(
            f"{AUTH_URL}/api/v1/auth/visitor/handoff",
            json={"anonymousId": ANONYMOUS_ID},
            name="auth visitor handoff",
        )

    @task
    def active_questionnaire(self):
        self.client.get(
            f"{FORM_URL}/api/v1/questionnaires/active",
            name="form active questionnaire",
        )

    @task
    def submit_survey(self):
        self.client.post(
            f"{FORM_URL}/api/v1/surveys",
            json={"anonymousId": ANONYMOUS_ID, "hasFever": True, "hasCough": True},
            name="form submit survey",
        )

    @task
    def validate_gateway(self):
        self.client.post(
            f"{GATEWAY_URL}/api/v1/gate/validate",
            json={"token": "invalid-demo-token"},
            name="gateway validate qr",
        )

    @task
    def health_status_stats(self):
        self.client.get(
            f"{PROMOTION_URL}/api/v1/health-status/stats",
            name="promotion health stats",
        )
