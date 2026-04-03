# Use a standard JRE base that has full Multi-Arch support (amd64 + arm64)
FROM eclipse-temurin:17-jre

# Metadata for GitHub Container Registry
LABEL org.opencontainers.image.source=https://github.com/krishjp/minedustry-docker
LABEL org.opencontainers.image.description="Mindustry Server Docker Image"

# Set the working directory
WORKDIR /opt/mindustry

# Install wget to fetch the server jar
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Download the latest stable server release
RUN wget https://github.com/Anuken/Mindustry/releases/latest/download/server-release.jar

# Create a config directory for persistent data
RUN mkdir config

# Expose the default Mindustry port
EXPOSE 6567/tcp
EXPOSE 6567/udp

# Run the server
# We use -Djava.net.preferIPv4Stack=true to avoid networking issues on some clouds
# We also specify the data directory so configs/maps are easier to manage
CMD ["java", "-Djava.net.preferIPv4Stack=true", "-jar", "server-release.jar", "host", "-config", "/opt/mindustry/config"]