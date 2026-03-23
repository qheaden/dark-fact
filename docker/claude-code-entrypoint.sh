#!/bin/bash
set -e

if [ ! -f /home/claude/.claude.json ]; then
    echo "Error: /home/claude/.claude.json is not mounted." >&2
    echo "Mount your Claude auth file with: -v /path/to/.claude.json:/home/claude/.claude.json" >&2
    exit 1
fi

if [ -f /workspace ]; then
    echo "Error: /workspace is a file, not a directory." >&2
    echo "Mount a directory with: -v /path/to/your/project:/workspace" >&2
    exit 1
fi

if [ ! -d /workspace ]; then
    echo "Error: /workspace is not mounted." >&2
    echo "Mount a directory with: -v /path/to/your/project:/workspace" >&2
    exit 1
fi

cd /workspace

exec claude "$@"
