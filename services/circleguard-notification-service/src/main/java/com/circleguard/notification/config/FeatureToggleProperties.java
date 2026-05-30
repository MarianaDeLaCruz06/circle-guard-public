package com.circleguard.notification.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "circleguard.features.notifications")
public class FeatureToggleProperties {

    private Channel email = new Channel(true);
    private Channel sms = new Channel(true);
    private Channel push = new Channel(true);

    public Channel getEmail() { return email; }
    public void setEmail(Channel email) { this.email = email; }

    public Channel getSms() { return sms; }
    public void setSms(Channel sms) { this.sms = sms; }

    public Channel getPush() { return push; }
    public void setPush(Channel push) { this.push = push; }

    public static class Channel {
        private boolean enabled;

        public Channel() {}
        public Channel(boolean enabled) { this.enabled = enabled; }

        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }
    }
}
