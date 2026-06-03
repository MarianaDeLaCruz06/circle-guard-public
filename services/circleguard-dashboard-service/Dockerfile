# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-dashboard-service:bootJar
#   docker build -f services/circleguard-dashboard-service/Dockerfile -t circleguard-dashboard-service:local .
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-dashboard-service/build/libs/*.jar app.jar

EXPOSE 8084

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
