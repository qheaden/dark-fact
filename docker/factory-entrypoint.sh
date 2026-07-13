#!/bin/bash
set -e
set -o pipefail

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

if [ ! -d /kanban ]; then
    echo "Error: /kanban is not mounted." >&2
    exit 1
fi

cd /workspace

if [ -f /home/opencode/.env ]; then
    source /home/opencode/.env
fi

shopt -s nullglob

echo "Kanban worker started; watching /kanban/2-ready-for-work for tickets."

while true; do
    tickets=(/kanban/2-ready-for-work/*.md)

    if [ "${#tickets[@]}" -eq 0 ]; then
        echo "No tickets ready for work; checking again in 10 seconds."
        sleep 10
        continue
    fi

    ticket_path="${tickets[0]}"
    in_progress_path="/kanban/3-in-progress/$(basename "$ticket_path")"
    worklog_path="/kanban/worklogs/$(basename "${in_progress_path%.md}").log"
    echo "Ready for work: ${ticket_path}"
    mv -- "$ticket_path" "$in_progress_path"
    echo "In progress: ${in_progress_path}"
    echo "Writing OpenCode output to: ${worklog_path}"

    if opencode run "Please implement the ticket in ${in_progress_path}. If the ticket has a task list, please implement each task one at a time." 2>&1 | tee "$worklog_path"; then
        echo "Completed ticket: ${in_progress_path}"
    else
        echo "OpenCode failed while processing ticket: ${in_progress_path}" >&2
    fi

    echo "Moving ticket to review: ${in_progress_path}"
    mv -- "$in_progress_path" /kanban/4-in-review/
    echo "In review: /kanban/4-in-review/$(basename "$in_progress_path")"
done
