package com.circleguard.identity.service;

import com.circleguard.identity.model.IdentityMapping;
import com.circleguard.identity.repository.IdentityMappingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class IdentityVaultServiceTest {

    private IdentityMappingRepository repository;
    private IdentityVaultService service;

    @BeforeEach
    void setUp() {
        repository = mock(IdentityMappingRepository.class);
        service = new IdentityVaultService(repository);
        ReflectionTestUtils.setField(service, "hashSalt", "test-hash-salt");
    }

    @Test
    void getOrCreateAnonymousId_ReturnsExistingMapping() {
        UUID existingId = UUID.randomUUID();
        when(repository.findByIdentityHash(anyString())).thenReturn(Optional.of(
                IdentityMapping.builder().anonymousId(existingId).build()
        ));

        UUID result = service.getOrCreateAnonymousId("user@example.com");

        assertEquals(existingId, result);
    }

    @Test
    void getOrCreateAnonymousId_SavesNewMappingWhenMissing() {
        UUID newId = UUID.randomUUID();
        when(repository.findByIdentityHash(anyString())).thenReturn(Optional.empty());
        when(repository.save(org.mockito.ArgumentMatchers.any(IdentityMapping.class)))
                .thenAnswer(invocation -> {
                    IdentityMapping mapping = invocation.getArgument(0);
                    mapping.setAnonymousId(newId);
                    return mapping;
                });

        UUID result = service.getOrCreateAnonymousId("new-user@example.com");

        ArgumentCaptor<IdentityMapping> captor = ArgumentCaptor.forClass(IdentityMapping.class);
        verify(repository).save(captor.capture());
        assertEquals(newId, result);
        assertEquals("new-user@example.com", captor.getValue().getRealIdentity());
        assertNotNull(captor.getValue().getIdentityHash());
    }
}
