package com.circleguard.form.service;

import com.circleguard.form.model.HealthSurvey;
import com.circleguard.form.model.Questionnaire;
import com.circleguard.form.repository.HealthSurveyRepository;
import org.junit.jupiter.api.Test;
import org.springframework.kafka.core.KafkaTemplate;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class HealthSurveyServiceTest {

    @Test
    void submitSurvey_PublishesSurveySubmittedEvent() {
        HealthSurveyRepository repository = mock(HealthSurveyRepository.class);
        QuestionnaireService questionnaireService = mock(QuestionnaireService.class);
        SymptomMapper symptomMapper = mock(SymptomMapper.class);
        KafkaTemplate<String, Object> kafkaTemplate = mock(KafkaTemplate.class);
        HealthSurveyService service = new HealthSurveyService(repository, questionnaireService, symptomMapper, kafkaTemplate);

        UUID anonymousId = UUID.randomUUID();
        HealthSurvey survey = HealthSurvey.builder().anonymousId(anonymousId).build();
        Questionnaire questionnaire = Questionnaire.builder().isActive(true).build();

        when(questionnaireService.getActiveQuestionnaire()).thenReturn(Optional.of(questionnaire));
        when(symptomMapper.hasSymptoms(survey, questionnaire)).thenReturn(true);
        when(repository.save(survey)).thenReturn(survey);

        HealthSurvey saved = service.submitSurvey(survey);

        assertTrue(saved.getHasFever());
        verify(kafkaTemplate).send(eq("survey.submitted"), eq(anonymousId.toString()), any());
    }
}
