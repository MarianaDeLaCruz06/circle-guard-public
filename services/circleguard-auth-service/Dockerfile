# Build from the repository root AFTER the JAR has been produced by Gradle:
#   ./gradlew :services:circleguard-auth-service:bootJar
#   docker build -f services/circleguard-auth-service/Dockerfile -t circleguard-auth-service:local .
#
# The Jenkins pipeline runs the Gradle build in a previous stage; this
# Dockerfile only packages the pre-built JAR. This avoids recompiling the
# whole project per image and avoids needing Maven Central access during
# `docker build`.
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY services/circleguard-auth-service/build/libs/*.jar app.jar

EXPOSE 8180

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
