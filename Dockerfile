# ========================
# 1. Build Stage
# ========================
FROM maven:3.9.9-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy Maven project files (for dependency caching)
COPY pom.xml mvnw ./
COPY .mvn .mvn

# Pre-fetch dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source
COPY src src

# Build Spring Boot fat JAR
RUN ./mvnw clean package -DskipTests

# ========================
# 2. Production Stage
# ========================
FROM eclipse-temurin:17-jre-jammy

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy built JAR
COPY --from=builder /app/target/spring-petclinic-*.jar app.jar

# Change ownership
RUN chown spring:spring app.jar
USER spring

# Expose port
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
