# ---------- Stage 1: Build ----------
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Copy only pom first (better caching)
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source
COPY src ./src

# Build jar
RUN mvn clean package -DskipTests


# ---------- Stage 2: Runtime ----------
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy built jar
COPY --from=build /app/target/*.jar app.jar

# Expose port (only needed for web apps)
EXPOSE 8080

# Run application
ENTRYPOINT ["java","-jar","app.jar"]
