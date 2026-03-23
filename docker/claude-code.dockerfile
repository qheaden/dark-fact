FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo

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

# ~/.claude/  — credentials, settings, project memory, keybindings
# ~/.claude.json is a file (OAuth/global state); bind-mount it separately at runtime
VOLUME ["/home/claude/.claude"]

USER root
COPY docker/claude-code-entrypoint.sh /claude-code-entrypoint.sh
RUN chmod +x /claude-code-entrypoint.sh

USER claude

ENTRYPOINT ["/claude-code-entrypoint.sh"]
