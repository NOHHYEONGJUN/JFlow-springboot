# Build stage
FROM maven:3.9.6-eclipse-temurin-17-focal AS build
WORKDIR /app

# target jar copy
COPY target/*.jar app.jar

# Run stage  
FROM eclipse-temurin:17-jre-focal
WORKDIR /app
COPY --from=build /app/app.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]