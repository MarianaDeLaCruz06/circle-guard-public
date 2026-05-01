# Build from the repository root:
# docker build -f services/circleguard-promotion-service/Dockerfile -t circleguard-promotion-service:local .
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /workspace

COPY gradlew gradlew.bat settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
COPY services ./services

RUN sed -i 's/\r$//' gradlew && chmod +x gradlew && ./gradlew :services:circleguard-promotion-service:bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

ENV SPRING_PROFILES_ACTIVE=docker

COPY --from=build /workspace/services/circleguard-promotion-service/build/libs/*.jar app.jar

EXPOSE 8088

USER spring:spring

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
