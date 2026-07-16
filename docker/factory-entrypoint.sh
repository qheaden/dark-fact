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
    echo "No API credentials configured. Starting the OpenCode login flow."
    opencode auth login

    if [ ! -f "$AUTH_JSON" ] || [ "$(wc -c < "$AUTH_JSON")" -le 2 ]; then
        echo "Error: OpenCode login did not create credentials at ${AUTH_JSON}." >&2
        exit 1
    fi
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
FACTORY_CONFIG="/kanban/factory.env"
TRANSITION_HOOK="/kanban/on-ticket-transition.sh"

run_transition_hook() {
    local ticket_path="$1"
    local new_state="$2"

    if [ -f "$TRANSITION_HOOK" ] && ! bash "$TRANSITION_HOOK" "$ticket_path" "$new_state"; then
        echo "Warning: Ticket transition hook failed for ${ticket_path} (${new_state})." >&2
    fi
}

echo "Kanban worker started; watching /kanban/2-ready-for-work for tickets."

while true; do
    sleep 10

    if [ ! -f "$FACTORY_CONFIG" ]; then
        echo "Error: Required factory configuration is missing: ${FACTORY_CONFIG}. Waiting 10 seconds." >&2
        continue
    fi

    unset OPENCODE_MODEL OPENCODE_VARIANT
    if ! source "$FACTORY_CONFIG"; then
        echo "Error: Could not load factory configuration: ${FACTORY_CONFIG}. Waiting 10 seconds." >&2
        continue
    fi

    # Factory configuration may be edited on Windows with CRLF line endings.
    OPENCODE_MODEL="${OPENCODE_MODEL%$'\r'}"
    OPENCODE_VARIANT="${OPENCODE_VARIANT%$'\r'}"

    if [ -z "$OPENCODE_MODEL" ] || [ -z "$OPENCODE_VARIANT" ]; then
        echo "Error: ${FACTORY_CONFIG} must define non-empty OPENCODE_MODEL and OPENCODE_VARIANT values. Waiting 10 seconds." >&2
        continue
    fi

    tickets=(/kanban/2-ready-for-work/*.md)

    if [ "${#tickets[@]}" -eq 0 ]; then
        echo "No tickets ready for work; checking again in 10 seconds."
        continue
    fi

    ticket_path="${tickets[0]}"
    in_progress_path="/kanban/3-in-progress/$(basename "$ticket_path")"
    worklog_path="/kanban/worklogs/$(basename "${in_progress_path%.md}").log"
    echo "Ready for work: ${ticket_path}"
    mv -- "$ticket_path" "$in_progress_path"
    run_transition_hook "$in_progress_path" "in-progress"
    echo "In progress: ${in_progress_path}"
    echo "Using model ${OPENCODE_MODEL} with variant ${OPENCODE_VARIANT}."
    echo "Writing OpenCode output to: ${worklog_path}"

    prompt="Please implement the ticket in ${in_progress_path}.

Review /kanban/MEMORIES.md first for relevant context from previous tickets.

If the ticket has a task list, please implement each task one at a time.

When finished, save important implementation notes in the ticket's Notes section and update /kanban/MEMORIES.md with any relevant information that should carry forward to future ticket work."

    if opencode run --model "$OPENCODE_MODEL" --variant "$OPENCODE_VARIANT" "$prompt" 2>&1 | tee "$worklog_path"; then
        echo "Completed ticket: ${in_progress_path}"
        echo "Moving ticket to review: ${in_progress_path}"
        in_review_path="/kanban/4-in-review/$(basename "$in_progress_path")"
        mv -- "$in_progress_path" "$in_review_path"
        run_transition_hook "$in_review_path" "in-review"
        echo "In review: ${in_review_path}"
    else
        echo "OpenCode failed while processing ticket; returning it to ready for work: ${in_progress_path}" >&2
        ready_path="/kanban/2-ready-for-work/$(basename "$in_progress_path")"
        mv -- "$in_progress_path" "$ready_path"
        run_transition_hook "$ready_path" "ready-for-work"
        echo "Ready for work: ${ready_path}"
        echo "Retrying in 10 seconds."
    fi
done
