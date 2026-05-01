package com.circleguard.auth.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class QrTokenServiceTest {

    private static final String SECRET = "test-qr-secret-key-with-at-least-32-characters";

    @Test
    void generateQrToken_IncludesSubjectAndExpiration() {
        QrTokenService service = new QrTokenService(SECRET, 60000);
        UUID anonymousId = UUID.randomUUID();

        String token = service.generateQrToken(anonymousId);

        Claims claims = Jwts.parserBuilder()
                .setSigningKey(Keys.hmacShaKeyFor(SECRET.getBytes()))
                .build()
                .parseClaimsJws(token)
                .getBody();

        assertEquals(anonymousId.toString(), claims.getSubject());
        assertNotNull(claims.getExpiration());
    }
}
