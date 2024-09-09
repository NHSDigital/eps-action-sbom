# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set environment variables for versions with default values
ARG POETRY_VERSION=1.8.0
ARG NODE_VERSION=18
ARG CYCLONE_PYTHON_VERSION=4.5.0
ARG CYCLONE_NPM_VERSION=1.19.3

# Install system dependencies and tools
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Install cyclonedx
RUN pip install cyclonedx-bom==${CYCLONE_PYTHON_VERSION}
RUN npm install -g @cyclonedx/cyclonedx-npm@${CYCLONEDX_VERSION}

# Install Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

WORKDIR /github/workspace

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
