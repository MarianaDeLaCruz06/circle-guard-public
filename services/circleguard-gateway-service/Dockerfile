# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-gateway-service:bootJar
#   docker build -f services/circleguard-gateway-service/Dockerfile -t circleguard-gateway-service:local .
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-gateway-service/build/libs/*.jar app.jar

EXPOSE 8087

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
