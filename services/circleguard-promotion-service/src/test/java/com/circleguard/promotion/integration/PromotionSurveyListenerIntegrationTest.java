package com.circleguard.promotion.integration;

import com.circleguard.promotion.listener.SurveyListener;
import com.circleguard.promotion.service.HealthStatusService;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

@Tag("integration")
class PromotionSurveyListenerIntegrationTest {

    @Test
    void certificateValidated_WithApprovedStatus_RestoresUserToActive() {
        HealthStatusService healthStatusService = mock(HealthStatusService.class);
        SurveyListener listener = new SurveyListener(healthStatusService);

        listener.onCertificateValidated(Map.of(
                "anonymousId", "tester-123",
                "status", "APPROVED"
        ));

        verify(healthStatusService).updateStatus("tester-123", "ACTIVE");
    }
}
