package com.circleguard.form.integration;

import com.circleguard.form.model.HealthSurvey;
import com.circleguard.form.model.Questionnaire;
import com.circleguard.form.repository.HealthSurveyRepository;
import com.circleguard.form.service.HealthSurveyService;
import com.circleguard.form.service.QuestionnaireService;
import com.circleguard.form.service.SymptomMapper;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@Tag("integration")
class FormPromotionEventIntegrationTest {

    @Test
    void submitSurvey_EmitsEventConsumableByPromotionService() {
        HealthSurveyRepository repository = mock(HealthSurveyRepository.class);
        QuestionnaireService questionnaireService = mock(QuestionnaireService.class);
        SymptomMapper symptomMapper = mock(SymptomMapper.class);
        KafkaTemplate<String, Object> kafkaTemplate = mock(KafkaTemplate.class);
        HealthSurveyService service = new HealthSurveyService(repository, questionnaireService, symptomMapper, kafkaTemplate);

        UUID anonymousId = UUID.randomUUID();
        HealthSurvey survey = HealthSurvey.builder().anonymousId(anonymousId).build();
        Questionnaire questionnaire = Questionnaire.builder().title("Daily").isActive(true).build();

        when(questionnaireService.getActiveQuestionnaire()).thenReturn(Optional.of(questionnaire));
        when(symptomMapper.hasSymptoms(survey, questionnaire)).thenReturn(true);
        when(repository.save(survey)).thenReturn(survey);

        service.submitSurvey(survey);

        verify(kafkaTemplate).send(eq("survey.submitted"), eq(anonymousId.toString()), any());
    }
}
