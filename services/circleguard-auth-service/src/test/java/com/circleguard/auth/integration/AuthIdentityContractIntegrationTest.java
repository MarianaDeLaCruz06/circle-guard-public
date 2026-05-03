package com.circleguard.auth.integration;

import com.circleguard.auth.client.IdentityClient;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

@Tag("integration")
class AuthIdentityContractIntegrationTest {

    @Test
    void identityClient_ConsumesIdentityMappingContract() throws Exception {
        UUID anonymousId = UUID.randomUUID();
        HttpServer server = HttpServer.create(new InetSocketAddress(8083), 0);
        server.createContext("/api/v1/identities/map", exchange -> {
            byte[] response = ("{\"anonymousId\":\"" + anonymousId + "\"}").getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream body = exchange.getResponseBody()) {
                body.write(response);
            }
        });

        try {
            server.start();
            UUID result = new IdentityClient().getAnonymousId("user@example.com");
            assertEquals(anonymousId, result);
        } finally {
            server.stop(0);
        }
    }
}
