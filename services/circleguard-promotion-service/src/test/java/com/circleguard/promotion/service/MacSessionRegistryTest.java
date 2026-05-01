package com.circleguard.promotion.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MacSessionRegistryTest {

    private StringRedisTemplate redisTemplate;
    private ValueOperations<String, String> valueOperations;
    private MacSessionRegistry registry;

    @BeforeEach
    void setUp() {
        redisTemplate = mock(StringRedisTemplate.class);
        valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        registry = new MacSessionRegistry(redisTemplate);
    }

    @Test
    void registerSession_NormalizesMacAndStoresWithTtl() {
        registry.registerSession("AA:BB:CC", "anon-1");

        verify(valueOperations).set(eq("session:mac:aa:bb:cc"), eq("anon-1"), eq(Duration.ofHours(8)));
    }

    @Test
    void getAnonymousId_ReadsNormalizedMacKey() {
        when(valueOperations.get("session:mac:aa:bb:cc")).thenReturn("anon-1");

        String result = registry.getAnonymousId("AA:BB:CC");

        assertEquals("anon-1", result);
    }

    @Test
    void closeSession_DeletesNormalizedMacKey() {
        registry.closeSession("AA:BB:CC");

        verify(redisTemplate).delete("session:mac:aa:bb:cc");
    }
}
