package com.circleguard.auth.client;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.UUID;

@Component
@Slf4j
public class IdentityClient {

    private static final String INSTANCE = "identityService";

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${circleguard.identity-service.url:http://localhost:8083}")
    private String identityServiceUrl;

    @CircuitBreaker(name = INSTANCE, fallbackMethod = "getAnonymousIdFallback")
    @Retry(name = INSTANCE)
    public UUID getAnonymousId(String realIdentity) {
        Map<String, String> request = Map.of("realIdentity", realIdentity);
        @SuppressWarnings("unchecked")
        Map<String, Object> response = restTemplate.postForObject(
                identityServiceUrl + "/api/v1/identities/map",
                request,
                Map.class
        );
        if (response == null || !response.containsKey("anonymousId")) {
            throw new IllegalStateException("identity-service returned empty body");
        }
        return UUID.fromString(response.get("anonymousId").toString());
    }

    @SuppressWarnings("unused")
    private UUID getAnonymousIdFallback(String realIdentity, Throwable ex) {
        log.warn("identity-service unavailable (circuit open or retries exhausted) — emitting deterministic fallback id. cause={}", ex.toString());
        return UUID.nameUUIDFromBytes(("fallback::" + realIdentity).getBytes());
    }
}
