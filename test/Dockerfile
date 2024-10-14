FROM ubuntu:24.04

# Install dependencies needed for the SBOM script and tests
RUN apt-get update && \
    apt-get install -y \
    bash \
    make \
    docker.io \
    curl \
    jq \
    git \
    bats \
    gcc \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    python3-openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install ASDF
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1; \
    echo '. /root/.asdf/asdf.sh' >> ~/.bashrc; \
    echo '. /root/.asdf/completions/asdf.bash' >> ~/.bashrc; \
    echo 'PATH="$PATH:/root/.asdf/bin/"' >> ~/.bashrc;

ENV PATH="$PATH:/root/.asdf/bin/"

# Install ASDF plugins
RUN asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git; \
    asdf plugin add actionlint; \
    asdf plugin add python; \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git; \
    asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git;

# Create a directory for the working files
WORKDIR /tmp

# Copy the run-sbom-scan.sh script to the container
COPY test/.tool-versions /tmp/
COPY test/Makefile /tmp/

RUN asdf install

COPY run-sbom-scan.sh /tmp/
COPY check-sbom-issues-against-ignores.sh /tmp/
# Ensure the SBOM script is executable
RUN chmod +x /tmp/run-sbom-scan.sh
RUN chmod +x /tmp/check-sbom-issues-against-ignores.sh

WORKDIR /working

ENTRYPOINT [ "/tmp/run-sbom-scan.sh"]
