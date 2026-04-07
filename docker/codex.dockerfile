FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git

# Install Node.js 22.x for Codex CLI
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

RUN useradd -m -s /bin/bash codex \
    && echo "codex ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/codex

# Install OpenAI Codex CLI
RUN npm install -g @openai/codex

USER root
COPY --chmod=0555 docker/codex-entrypoint.sh /codex-entrypoint.sh
COPY --chmod=0444 ssl-certs/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

USER codex

RUN mkdir -p /home/codex/.codex

# ~/.codex/ -- Codex CLI local state
VOLUME ["/home/codex/.codex"]

ENTRYPOINT ["/codex-entrypoint.sh"]
