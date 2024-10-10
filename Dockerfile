FROM ubuntu:24.04

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y dist-upgrade \
    && apt-get -y install --no-install-recommends htop vim curl git build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev libbz2-dev \
    zlib1g-dev unixodbc unixodbc-dev libsecret-1-0 libsecret-1-dev libsqlite3-dev \
    jq apt-transport-https ca-certificates gnupg-agent \
    software-properties-common bash-completion python3-pip make libbz2-dev \
    libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev liblzma-dev libyaml-dev bats bats-support bats-assert bats-file \
    python3 python3-pip python3-dev

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
    asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git; \
    asdf plugin add direnv; \
    asdf plugin add ruby;

# Install Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install Syft
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Set the working directory
WORKDIR /working

# Add entrypoint scripts
ADD entrypoint.sh /entrypoint.sh
ADD check-sbom-issues-against-ignores.sh /check-sbom-issues-against-ignores.sh

# Set the umask
RUN echo "umask 000" >> /etc/profile

ENTRYPOINT ["/entrypoint.sh"]
