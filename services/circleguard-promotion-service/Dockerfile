# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-promotion-service:bootJar
#   docker build -f services/circleguard-promotion-service/Dockerfile -t circleguard-promotion-service:local .
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-promotion-service/build/libs/*.jar app.jar

EXPOSE 8088

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
