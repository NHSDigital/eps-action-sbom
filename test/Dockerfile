FROM ubuntu:22.04

# This dockerfile is used to build the test environment for the bats tests.
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

ARG ASDF_VERSION
COPY ../.tool-versions.asdf /tmp/.tool-versions.asdf

# Add amd64 architecture if on arm64
RUN if [ "$TARGETARCH" == "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then dpkg --add-architecture amd64; fi

# Create a non-root user with sudo privileges
RUN useradd -ms /bin/bash eps-sbom-user && \
    usermod -aG sudo eps-sbom-user && \
    echo 'eps-sbom-user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install required packages
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y dist-upgrade \
    && apt-get -y install --no-install-recommends htop vim curl git build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev libbz2-dev \
    zlib1g-dev unixodbc unixodbc-dev libsecret-1-0 libsecret-1-dev libsqlite3-dev \
    jq apt-transport-https ca-certificates gnupg-agent \
    software-properties-common bash-completion python3-pip make libbz2-dev \
    libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev liblzma-dev libyaml-dev \
    python3 python3-pip python3-dev


# Install ASDF
RUN ASDF_VERSION=$(awk '!/^#/ && NF {print $1; exit}' /tmp/.tool-versions.asdf) && \
    wget -O /tmp/asdf.tar.gz https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-amd64.tar.gz; \
    tar -xvzf /tmp/asdf.tar.gz; \
    mv asdf /usr/bin

# Switch to the new user
USER eps-sbom-user
WORKDIR /home/eps-sbom-user

ENV PATH="$PATH:/home/eps-sbom-user/.asdf/shims/"

# Install ASDF plugins
RUN asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git; \
    asdf plugin add actionlint; \
    asdf plugin add python; \
    asdf plugin add golang; \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git; \
    asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git;

# Pre-build the tool versions we'll use, so we don't have to download it every time.
WORKDIR /build
COPY .tool-versions .
RUN asdf install

# Set the workdir to what we'll actually use
WORKDIR /working

# Files to execute when the docker container starts up
COPY ../entrypoint.sh /home/eps-sbom-user/entrypoint.sh

# Set the umask so that the files created by docker can be universally accessed. 
# Lets the tests successfully teardown.
RUN echo "umask 000" >> ~/.profile

ENTRYPOINT ["/home/eps-sbom-user/entrypoint.sh"]
