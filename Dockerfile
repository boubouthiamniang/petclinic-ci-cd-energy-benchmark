# ========================
# 1. Build Stage
# ========================
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy Maven project files and wrapper
COPY pom.xml mvnw ./
COPY .mvn .mvn

# Make mvnw executable
RUN chmod +x mvnw

# Pre-fetch dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build Spring Boot fat JAR
RUN ./mvnw clean package -DskipTests

# ========================
# 2. Production Stage
# ========================
FROM eclipse-temurin:17-jre-jammy

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# Copy built JAR (fail if not found)
COPY --from=builder /app/target/spring-petclinic-*.jar app.jar

RUN chown spring:spring app.jar
USER spring

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
