FROM ubuntu:24.04

# Create a non-root user and group with a specified UID and GID
# This is so that docker doesn't install any node-modules etc. as root
# in the mounted volume
ARG USER_NAME=myuser
ARG USER_UID=1000
ARG USER_GID=1000

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
    asdf plugin add golang; \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git; \
    asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git;

# Pre-build the tool versions we'll use, so we don't have to download it every time.
WORKDIR /build
ADD test/.tool-versions .
RUN asdf install

# Set the workdir to what we'll actually use
WORKDIR /working

# Files to execute when the docker container starts up
ADD entrypoint.sh /entrypoint.sh

# Set the umask so that the files created by docker can be universally accessed. 
# Lets the tests successfully teardown.
RUN echo "umask 000" >> /etc/profile

# Switch to the non-root user
USER $USER_NAME

ENTRYPOINT ["/entrypoint.sh"]
