package com.circleguard.notification.service;

import com.circleguard.notification.config.FeatureToggleProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationDispatcher {

    private final EmailService emailService;
    private final SmsService smsService;
    private final PushService pushService;
    private final TemplateService templateService;
    private final FeatureToggleProperties featureToggles;

    public void dispatch(String userId, String status) {
        log.info("Dispatching contextual multi-channel notifications for user: {} with status: {}", userId, status);

        List<CompletableFuture<Void>> activeChannels = new ArrayList<>();

        if (featureToggles.getEmail().isEnabled()) {
            String emailContent = templateService.generateEmailContent(status, userId);
            activeChannels.add(emailService.sendAsync(userId, emailContent));
        } else {
            log.debug("Email channel disabled by feature toggle — skipping for user {}", userId);
        }

        if (featureToggles.getSms().isEnabled()) {
            String smsContent = templateService.generateSmsContent(status);
            activeChannels.add(smsService.sendAsync(userId, smsContent));
        } else {
            log.debug("SMS channel disabled by feature toggle — skipping for user {}", userId);
        }

        if (featureToggles.getPush().isEnabled()) {
            String pushContent = templateService.generatePushContent(status);
            Map<String, String> pushMetadata = templateService.generatePushMetadata(status);
            activeChannels.add(pushService.sendAsync(userId, pushContent, pushMetadata));
        } else {
            log.debug("Push channel disabled by feature toggle — skipping for user {}", userId);
        }

        if (activeChannels.isEmpty()) {
            log.warn("All notification channels are disabled — nothing dispatched for user {}", userId);
            return;
        }

        CompletableFuture.allOf(activeChannels.toArray(new CompletableFuture[0]))
                .handle((result, ex) -> {
                    if (ex != null) {
                        log.error("Error during multi-channel dispatch for user {}: {}", userId, ex.getMessage());
                    } else {
                        log.info("Multi-channel dispatch completed for user {} across {} channel(s)", userId, activeChannels.size());
                    }
                    return result;
                });
    }
}
