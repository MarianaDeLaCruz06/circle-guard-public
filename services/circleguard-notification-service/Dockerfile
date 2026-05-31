# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-notification-service:bootJar
#   docker build -f services/circleguard-notification-service/Dockerfile -t circleguard-notification-service:local .
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-notification-service/build/libs/*.jar app.jar

EXPOSE 8082

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
