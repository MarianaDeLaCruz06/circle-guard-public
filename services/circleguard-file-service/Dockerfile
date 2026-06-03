# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-file-service:bootJar
#   docker build -f services/circleguard-file-service/Dockerfile -t circleguard-file-service:local .
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-file-service/build/libs/*.jar app.jar

EXPOSE 8085

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
