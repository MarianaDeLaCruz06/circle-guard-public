# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-form-service:bootJar
#   docker build -f services/circleguard-form-service/Dockerfile -t circleguard-form-service:local .
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-form-service/build/libs/*.jar app.jar

EXPOSE 8086

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
