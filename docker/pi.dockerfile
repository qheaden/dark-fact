FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git

# Install Node.js 24 via nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && \. "$HOME/.nvm/nvm.sh" \
    && nvm install 24 \
    && ln -sf "$(dirname $(nvm which 24))" /usr/local/bin/node-bin
ENV PATH="/usr/local/bin/node-bin:$PATH"

RUN useradd -m -s /bin/bash pi \
    && echo "pi ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pi

# Install Pi coding agent
RUN npm install -g @mariozechner/pi-coding-agent

USER root
COPY --chmod=0555 docker/pi-entrypoint.sh /pi-entrypoint.sh
COPY --chmod=0444 ssl-certs/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

USER pi

RUN mkdir -p /home/pi/.pi/agent

# ~/.pi/agent/ -- Pi CLI local state
VOLUME ["/home/pi/.pi/agent"]

ENTRYPOINT ["/pi-entrypoint.sh"]
