# Dark Fact

A setup for running an autonomous coding agent as a **dark factory** of software development.

The term comes from manufacturing: a "dark factory" (or "lights-out factory") is a fully automated production facility that operates without human presence. Dark Fact  applies the same idea to software — containerized AI coding agents that run autonomously on your codebase without requiring human approval at every step.

> **Warning:** Fully autonomous coding agents can be dangerous even inside a container. A compromised or misbehaving agent can still make outbound network requests, exfiltrate data, or interact with external services. This repo does not implement any network filtering — that is your responsibility. Consider pairing these containers with a network firewall or egress proxy appropriate for your threat model.

## How It Works

Each dark factory is a Docker container that:

1. Mounts a local workspace directory as `/workspace`
2. Stores credentials and configuration in persistent container volumes
3. Mounts a `shared-skills/` directory so the agent has access to custom skills
4. Mounts a factory-specific kanban board at `/kanban`
5. Starts the agent with a permissive configuration to bypass approval prompts

The factory continuously works through ready kanban tickets. Because the workspace is a bind mount, all changes the agent makes are immediately visible on the host.

Named Docker volumes persist each factory's agent state, credentials, and configuration across restarts.

## Prerequisites

- Docker with Buildx support
- Python 3 (for the factory creation scripts)

## Building the Images

Build all images at once:

```bash
docker buildx bake
```

The factory target can also be built explicitly:

```bash
docker buildx bake factory
```

This produces the local `dark-factory` image.

## Building a Dark Factory

## Create a Factory

```bash
python create-factory.py /path/to/your/project \
    --name my-dark-factory \
    --env MY_ENVIRONMENT_VARIABLE=value
```

**Options:**

| Flag | Description |
|------|-------------|
| `workspace-path` | (required) Path to the project directory to mount as `/workspace` |
| `--name` | (required) Name for the Docker container |
| `--env` | Environment variable, e.g. `ANTHROPIC_API_KEY=sk-...`. Repeatable. |
| `--port` | Port mapping, e.g. `8000:8000`. Repeatable. |

## Start the Factory

```bash
docker start -ia my-dark-factory
```

The factory watches `kanbans/my-dark-factory/2-ready-for-work/` for tickets. Each ticket is moved to `3-in-progress` while OpenCode works on it, then to `4-in-review` after OpenCode exits. The factory runs continuously; attach with `docker start -ia` to view its output.

On the first attached start without API-key credentials, the factory launches the interactive `opencode auth login` flow. This supports subscription-based provider login. The resulting authentication is stored in the factory's persistent data volume, so later starts do not require login again.

## Kanban

Creating a factory creates its board at `kanbans/<factory-name>/` with these states:

- `1-planning`
- `2-ready-for-work`
- `3-in-progress`
- `4-in-review`
- `5-done`
- `worklogs`

Each board also contains a required `factory-config.json` configuration file:

```json
{
  "modelId": "provider/model",
  "reasoningLevel": "reasoning-level",
  "enabled": true
}
```

Set `modelId` and `reasoningLevel` before starting the factory. Set `enabled` to `false` to pause ticket processing and back to `true` to resume it. The worker reloads the file before each ticket, so changes apply without restarting the container. If the file is missing, invalid, or either string value is empty while enabled, the worker logs an error and waits until it is corrected.

Each board also contains a `MEMORIES.md` file. Before working on a ticket, the agent reads this file for context from previous tickets; afterward, it updates the file with relevant information that should carry forward to future work.

Each board also contains a `GUIDANCE.md` file for long-lived preferences and instructions that apply to all work. The agent reads this file as system instructions before starting each ticket.

Each board also gets an `on-ticket-transition.sh` script for custom actions such as webhook notifications. After every transition performed by the worker, it runs the script with the ticket's new path as the first argument and its new state (`in-progress`, `in-review`, or `ready-for-work`) as the second argument. The script is optional at runtime; if it is removed, the worker continues normally. A hook failure is logged as a warning and does not stop ticket processing.

Create tickets from `TICKET-TEMPLATE.md`, then place them in `2-ready-for-work` for the factory to process. OpenCode output for each ticket is captured in `worklogs/` using the ticket filename with a `.log` extension. Factory kanbans and their tickets are ignored by Git.

## Skills

The `shared-skills/` directory is mounted into every factory container. Any skill you add there is immediately available to all factories without rebuilding their images.

See `shared-skills/README.md` for details.

## SSL Certificates

If your network requires custom root certificates (e.g. a corporate proxy like ZScaler), place the `.crt` or `.pem` files in `ssl-certs/`. The Dockerfiles install any certificates found there into the container's trust store at build time.

## Project Structure

```
├── docker/
│   ├── factory.dockerfile           # Factory container image
│   ├── factory-entrypoint.sh        # Validates credentials and processes tickets
├── create-factory.py                # Creates a factory container
├── kanbans/                         # Local per-factory kanban boards
├── shared-skills/                   # Custom skills mounted into every container
├── ssl-certs/                       # Extra SSL certificates for corporate networks
├── TICKET-TEMPLATE.md               # Template for kanban tickets
└── docker-bake.hcl                  # Buildx targets for the factory image
```
