# Stage 1: Build the application using Maven
FROM maven:3.9.5-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy pom and source files
COPY pom.xml .
COPY src ./src

# Build the application and skip tests for production
RUN mvn clean package -DskipTests

# Stage 2: Run the application using a minimal base image
FROM eclipse-temurin:17-jre-alpine

# Create app directory
WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose the application's port (default for Spring Boot)
EXPOSE 8080

# Define entrypoint
ENTRYPOINT ["java", "-jar", "app.jar"]