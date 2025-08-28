# ========================
# 1. Build Stage
# ========================
FROM maven:3.9.9-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy Maven project files first (for dependency caching)
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Download dependencies (cached layer)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build Spring Boot fat JAR
RUN ./mvnw clean package -DskipTests

# ========================
# 2. Production Stage
# ========================
FROM eclipse-temurin:17-jre-jammy

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

# Set workdir
WORKDIR /app

# Copy built JAR from builder
COPY --from=builder /app/target/spring-petclinic-*.jar app.jar

# Change permissions
RUN chown spring:spring app.jar
USER spring

# Expose application port
EXPOSE 8080

# Healthcheck (Spring Boot actuator endpoint)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
