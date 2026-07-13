FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git

COPY --chmod=0444 ssl-certs/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

RUN useradd -m -s /bin/bash opencode \
    && echo "opencode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/opencode

# Install OpenCode per https://opencode.ai/docs/
USER opencode
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH="/home/opencode/.opencode/bin:$PATH" \
    OPENCODE_ENABLE_EXA=1

USER root
COPY --chmod=0555 docker/factory-entrypoint.sh /factory-entrypoint.sh
COPY --chown=opencode:opencode docker/opencode-config.json /home/opencode/.config/opencode/opencode.json

USER opencode

# Make the directories and default configuration ahead of time so they are owned by the
# agent user and copied into a newly created volume.
RUN mkdir -p \
    /home/opencode/.config/opencode \
    /home/opencode/.local/share/opencode

# ~/.config/opencode/ — config, skills
# ~/.local/share/opencode/ — auth, sessions
VOLUME ["/home/opencode/.config/opencode"]
VOLUME ["/home/opencode/.local/share/opencode"]

ENTRYPOINT ["/factory-entrypoint.sh"]
