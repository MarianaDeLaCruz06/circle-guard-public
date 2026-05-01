package com.circleguard.promotion.integration;

import com.circleguard.promotion.repository.graph.CircleNodeRepository;
import com.circleguard.promotion.repository.graph.UserNodeRepository;
import com.circleguard.promotion.repository.jpa.SystemSettingsRepository;
import com.circleguard.promotion.service.HealthStatusService;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.mockito.Mockito;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Collections;
import java.util.HashMap;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@Tag("integration")
class PromotionNotificationEventIntegrationTest {

    @Test
    void updateStatus_PublishesStatusChangedEventForNotificationService() {
        UserNodeRepository userRepository = mock(UserNodeRepository.class);
        Neo4jClient neo4jClient = mock(Neo4jClient.class);
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        KafkaTemplate<String, Object> kafkaTemplate = mock(KafkaTemplate.class);
        SystemSettingsRepository settingsRepository = mock(SystemSettingsRepository.class);
        CircleNodeRepository circleRepository = mock(CircleNodeRepository.class);
        HealthStatusService service = new HealthStatusService(
                userRepository, neo4jClient, redisTemplate, kafkaTemplate, settingsRepository, circleRepository);

        Neo4jClient.UnboundRunnableSpec runnableSpec = Mockito.mock(Neo4jClient.UnboundRunnableSpec.class, Mockito.RETURNS_DEEP_STUBS);
        ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
        HashMap<String, Object> result = new HashMap<>();
        result.put("affectedContacts", Collections.emptyList());

        when(neo4jClient.query(anyString())).thenReturn(runnableSpec);
        when(runnableSpec.bind(anyString()).to(anyString())
                .bind(anyString()).to(anyString())
                .bind(ArgumentMatchers.anyLong()).to(anyString())
                .fetch().one()).thenReturn(Optional.of(result));
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(circleRepository.findNewlyFencedCircles("anon-1")).thenReturn(Collections.emptyList());

        service.updateStatus("anon-1", "CONFIRMED");

        verify(valueOperations).multiSet(anyMap());
        verify(kafkaTemplate).send(ArgumentMatchers.eq("promotion.status.changed"), ArgumentMatchers.eq("anon-1"), ArgumentMatchers.any());
    }
}
