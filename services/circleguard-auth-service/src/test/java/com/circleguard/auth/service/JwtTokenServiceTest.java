package com.circleguard.auth.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtTokenServiceTest {

    private static final String SECRET = "test-jwt-secret-key-with-at-least-32-characters";

    @Test
    void generateToken_IncludesAnonymousIdAndPermissions() {
        JwtTokenService service = new JwtTokenService(SECRET, 60000);
        UUID anonymousId = UUID.randomUUID();
        var auth = new UsernamePasswordAuthenticationToken(
                "user",
                null,
                List.of(new SimpleGrantedAuthority("identity:lookup"))
        );

        String token = service.generateToken(anonymousId, auth);

        Claims claims = Jwts.parserBuilder()
                .setSigningKey(Keys.hmacShaKeyFor(SECRET.getBytes()))
                .build()
                .parseClaimsJws(token)
                .getBody();

        assertEquals(anonymousId.toString(), claims.getSubject());
        assertTrue(claims.get("permissions", List.class).contains("identity:lookup"));
    }
}
