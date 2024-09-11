# Use an official Python runtime as a parent image, with version specified by ARG
FROM python:${PYTHON_VERSION}-slim

# Set environment variables for versions with default values
ENV NODE_VERSION=${NODE_VERSION:-18}
ENV CYCLONE_PYTHON_VERSION=${CYCLONE_PYTHON_VERSION:-4.5.0}
ENV CYCLONE_NPM_VERSION=${CYCLONE_NPM_VERSION:-1.19.3}

# Install system dependencies and tools
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Install cyclonedx
RUN pip install cyclonedx-bom==${CYCLONE_PYTHON_VERSION}
RUN npm install -g @cyclonedx/cyclonedx-npm@${CYCLONE_NPM_VERSION}

# Install Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

WORKDIR /github/workspace

COPY entrypoint.sh /entrypoint.sh
COPY check-sbom-issues-against-ignores.sh /check-sbom-issues-against-ignores.sh 

# Code file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]
