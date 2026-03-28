FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git

RUN useradd -m -s /bin/bash opencode \
    && echo "opencode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/opencode

# Install OpenCode per https://opencode.ai/docs/
USER opencode
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH="/home/opencode/.opencode/bin:$PATH"

USER root
COPY --chmod=0555 docker/opencode-entrypoint.sh /opencode-entrypoint.sh
COPY --chmod=0444 ssl-certs/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

# Copy skills into OpenCode's global skills directory (bind-mounted at runtime to override)
COPY --chown=opencode:opencode skills /home/opencode/.config/opencode/skills/

USER opencode

# Make the directories ahead of time so they are owned by the opencode user and not root
# when the volumes are mounted.
RUN mkdir -p \
    /home/opencode/.config/opencode \
    /home/opencode/.local/share/opencode

# ~/.config/opencode/ — config, skills
# ~/.local/share/opencode/ — auth, sessions
VOLUME ["/home/opencode/.config/opencode"]
VOLUME ["/home/opencode/.local/share/opencode"]

ENTRYPOINT ["/opencode-entrypoint.sh"]
