#!/bin/bash
set -e

AUTH_JSON="/home/opencode/.local/share/opencode/auth.json"

# Check for API credentials: non-empty auth file OR a known API key env var
has_auth=0
{ [ -f "$AUTH_JSON" ] && [ "$(wc -c < "$AUTH_JSON")" -gt 2 ]; } && has_auth=1
[ -n "$ANTHROPIC_API_KEY" ] && has_auth=1
[ -n "$OPENAI_API_KEY" ] && has_auth=1

if [ "$has_auth" -eq 0 ]; then
    echo "Error: No API credentials configured." >&2
    echo "Either populate ${AUTH_JSON} with authentication data, or pass an API key:" >&2
    echo "  -e ANTHROPIC_API_KEY=sk-ant-..." >&2
    echo "  -e OPENAI_API_KEY=sk-..." >&2
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

# Check for the factory configuration file.
CONFIG="/home/opencode/.config/opencode/opencode.json"
if [ ! -f "$CONFIG" ]; then
    echo "Error: The factory configuration file is not mounted." >&2
    exit 1
fi
cd /workspace

if [ -f /home/opencode/.env ]; then
    source /home/opencode/.env
fi

exec opencode "$@"
