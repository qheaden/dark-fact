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
