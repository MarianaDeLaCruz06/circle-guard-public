package com.circleguard.gateway.integration;

import com.circleguard.gateway.service.QrValidationService;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@Tag("integration")
class GatewayRedisIntegrationTest {

    private static final String SECRET = "test-qr-secret-key-with-at-least-32-characters";

    @Test
    void validateToken_UsesRedisHealthStatus() {
        String anonymousId = UUID.randomUUID().toString();
        String token = Jwts.builder()
                .setSubject(anonymousId)
                .signWith(Keys.hmacShaKeyFor(SECRET.getBytes()), SignatureAlgorithm.HS256)
                .compact();

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        QrValidationService service = new QrValidationService(redisTemplate);
        ReflectionTestUtils.setField(service, "qrSecret", SECRET);

        when(valueOperations.get("user:status:" + anonymousId)).thenReturn("CLEAR");
        assertTrue(service.validateToken(token).valid());

        when(valueOperations.get("user:status:" + anonymousId)).thenReturn("POTENTIAL");
        assertFalse(service.validateToken(token).valid());
    }
}
