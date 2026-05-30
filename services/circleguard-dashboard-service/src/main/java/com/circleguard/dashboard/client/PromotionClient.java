package com.circleguard.dashboard.client;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Date;
import java.util.Map;

@Component
@Slf4j
public class PromotionClient {

    private static final String INSTANCE = "promotionService";

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${circleguard.promotion-service.url:http://localhost:8088}")
    private String promotionServiceUrl;

    @CircuitBreaker(name = INSTANCE, fallbackMethod = "getHealthStatsFallback")
    @Retry(name = INSTANCE)
    @SuppressWarnings("unchecked")
    public Map<String, Object> getHealthStats() {
        return restTemplate.getForObject(
                promotionServiceUrl + "/api/v1/health-status/stats",
                Map.class
        );
    }

    @CircuitBreaker(name = INSTANCE, fallbackMethod = "getHealthStatsByDepartmentFallback")
    @Retry(name = INSTANCE)
    @SuppressWarnings("unchecked")
    public Map<String, Object> getHealthStatsByDepartment(String department) {
        return restTemplate.getForObject(
                promotionServiceUrl + "/api/v1/health-status/stats/department/" + department,
                Map.class
        );
    }

    @SuppressWarnings("unused")
    private Map<String, Object> getHealthStatsFallback(Throwable ex) {
        log.warn("promotion-service unavailable for global stats — returning degraded payload. cause={}", ex.toString());
        return Map.of(
                "error", "Service unavailable",
                "degraded", true,
                "timestamp", new Date()
        );
    }

    @SuppressWarnings("unused")
    private Map<String, Object> getHealthStatsByDepartmentFallback(String department, Throwable ex) {
        log.warn("promotion-service unavailable for department={} — returning degraded payload. cause={}", department, ex.toString());
        return Map.of(
                "error", "Service unavailable",
                "degraded", true,
                "department", department,
                "timestamp", new Date()
        );
    }
}
