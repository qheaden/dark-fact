FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git

# Install Node.js 22.x (required by Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

RUN useradd -m -s /bin/bash claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude

# Install Claude Code per https://code.claude.com/docs/en/overview
USER claude
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && rm -f /home/claude/.claude.json

ENV PATH="/home/claude/.local/bin:$PATH"

USER root
COPY --chmod=0555 docker/claude-code-entrypoint.sh /claude-code-entrypoint.sh
COPY --chmod=0444 ssl-certs/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

# Copy skills directory
COPY --chown=claude:claude skills /home/claude/.claude/skills/

USER claude

# ~/.claude/  — credentials, settings, project memory, keybindings
# ~/.claude.json is a file (OAuth/global state); bind-mount it separately at runtime
VOLUME ["/home/claude/.claude"]

ENTRYPOINT ["/claude-code-entrypoint.sh"]
