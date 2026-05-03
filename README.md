# Dark Fact

A setup for running CLI coding agents autonomously as a **dark factory** of software development.

The term comes from manufacturing: a "dark factory" (or "lights-out factory") is a fully automated production facility that operates without human presence. Dark Fact  applies the same idea to software — containerized AI coding agents that run autonomously on your codebase without requiring human approval at every step.

> **Warning:** Fully autonomous coding agents can be dangerous even inside a container. A compromised or misbehaving agent can still make outbound network requests, exfiltrate data, or interact with external services. This repo does not implement any network filtering — that is your responsibility. Consider pairing these containers with a network firewall or egress proxy appropriate for your threat model.

Four agent runtimes are supported:
- **Claude Code** — Anthropic's CLI coding agent
- **OpenCode** — an open-source coding agent
- **ChatGPT Codex** - OpenAI's CLI coding agent
- **Pi** - Pi coding agent

## How It Works

Each dark factory is a Docker container that:

1. Mounts a local workspace directory as `/workspace`
2. Mounts credentials so the agent can authenticate
3. Mounts a `skills/` directory so the agent has access to custom skills
4. Starts the agent with `--allow-dangerously-skip-permissions` (Claude Code), a permissive config (OpenCode), or `--yolo` (Codex) to bypass approval prompts

The agent runs interactively inside the container (`docker start -ia`), working autonomously on whatever task or prompt you give it. Because the workspace is a bind mount, all changes the agent makes are immediately visible on the host.

Named Docker volumes persist agent state (installed tools, cached data, config) across container restarts.

## Prerequisites

- Docker with Buildx support
- Python 3 (for the factory creation scripts)

## Building the Images

Build all images at once:

```bash
docker buildx bake
```

Or build individually:

```bash
docker buildx bake claude-code
docker buildx bake opencode
docker buildx bake codex
```

This produces three local images: `df-claude-code`, `df-opencode`, and `df-codex`.

## Building a Claude Code Dark Factory

### 1. Auth file (optional)

The script uses `claude-code-factory.json` in the repo root as the auth file by default. If that file doesn't exist, it is created automatically as an empty file and Claude Code will prompt you to log in on first run.

If you already have a Claude Code installation and want to reuse its credentials, copy your existing auth file:

```bash
cp ~/.claude.json claude-code-factory.json
```

You can also point the script at any path with `--claude-json`.

### 2. Create the container

```bash
python scripts/create-claude-code-factory.py /path/to/your/project \
    --name my-claude-factory
```

**Options:**

| Flag | Description |
|------|-------------|
| `workspace-path` | (required) Path to the project directory to mount as `/workspace` |
| `--name` | (required) Name for the Docker container |
| `--claude-json` | Path to the `.claude.json` auth file (default: `claude-code-factory.json`) |
| `--skills-dir` | Path to the skills directory (default: `skills/`) |
| `--port` | Port mapping, e.g. `8000:8000`. Repeatable. |

### 3. Start the factory

```bash
docker start -ia my-claude-factory
```

Claude Code launches inside the container. When it opens, select **bypass permissions** mode to allow it to operate without approval prompts. The `--allow-dangerously-skip-permissions` flag is pre-passed by the factory script to make that mode available.

## Building an OpenCode Dark Factory

### 1. Credentials (optional)

The script uses `opencode-factory-auth.json` in the repo root as the auth file by default. If it doesn't exist, it is created automatically as an empty file.

You can also pass API credentials directly via `--env` instead of using an auth file:

### 2. Create the container

```bash
# Using an API key
python scripts/create-opencode-factory.py /path/to/your/project \
    --name my-opencode-factory \
    --env ANTHROPIC_API_KEY=sk-ant-...

# Using an auth file
python scripts/create-opencode-factory.py /path/to/your/project \
    --name my-opencode-factory
```

**Options:**

| Flag | Description |
|------|-------------|
| `workspace-path` | (required) Path to the project directory to mount as `/workspace` |
| `--name` | (required) Name for the Docker container |
| `--auth-json` | Path to the OpenCode auth JSON file (default: `opencode-factory-auth.json`) |
| `--skills-dir` | Path to the skills directory (default: `skills/`) |
| `--config-json` | Path to a custom `opencode.json` config (auto-generated with permissive settings if omitted) |
| `--env` | Environment variable, e.g. `ANTHROPIC_API_KEY=sk-...`. Repeatable. |
| `--port` | Port mapping, e.g. `8000:8000`. Repeatable. |

### 3. Start the factory

```bash
docker start -ia my-opencode-factory
```

OpenCode launches inside the container with full permissions pre-approved and working directory set to `/workspace`.

## Building a Codex Dark Factory

### 1. Credentials (optional)

Codex uses `OPENAI_API_KEY` for authentication. Passing an API key is optional: if you do not provide one (via your shell or `--openai-api-key`), Codex will show a login menu when it starts.

### 2. Create the container

```bash
# Using OPENAI_API_KEY from your shell
python scripts/create-codex-factory.py /path/to/your/project \
    --name my-codex-factory

# Passing the API key directly
python scripts/create-codex-factory.py /path/to/your/project \
    --name my-codex-factory \
    --openai-api-key sk-...
```

**Options:**

| Flag | Description |
|------|-------------|
| `workspace-path` | (required) Path to the project directory to mount as `/workspace` |
| `--name` | (required) Name for the Docker container |
| `--openai-api-key` | OpenAI API key (defaults to `OPENAI_API_KEY` from your shell if set) |
| `--skills-dir` | Path to the skills directory (default: `skills/`) |
| `--port` | Port mapping, e.g. `8000:8000`. Repeatable. |
| `--dns` | DNS server for the container, e.g. `8.8.8.8`. Repeatable. |

### 3. Start the factory

```bash
docker start -ia my-codex-factory
```

Codex launches inside the container in `/workspace` with `--yolo` pre-passed by the factory script for autonomous operation.

## Building a Pi Dark Factory

### 1. Model Configuration

The script uses `configs/pi-models.json` as a user-editable file where you can define your custom providers and models. Note that built-in provider support is handled by the Pi agent separately, and this file is intended for your specific configuration overrides and extensions. If the file does not exist, it is created automatically as an empty configuration template.

### 2. Create the container

```bash
python scripts/create-pi-factory.py /path/to/your/project \
    --name my-pi-factory
```

**Options:**

| Flag | Description |
|------|-------------|
| `workspace-path` | (required) Path to the project directory to mount as `/workspace` |
| `--name` | (required) Name for the Docker container |
| `--skills-dir` | Path to the skills directory (default: `skills/`) |
| `--port` | Port mapping, e.g. `8000:8000`. Repeatable. |
| `--dns` | DNS server for the container, e.g. `8.8.8.8`. Repeatable. |

### 3. Start the factory

```bash
docker start -ia my-pi-factory
```

Pi launches inside the container in `/workspace`.

## Skills

The `skills/` directory is mounted into every factory container. Any skill you add there is immediately available to the running agent — no container rebuild needed.

See `skills/README.md` for details.

## SSL Certificates

If your network requires custom root certificates (e.g. a corporate proxy like ZScaler), place the `.crt` or `.pem` files in `ssl-certs/`. The Dockerfiles install any certificates found there into the container's trust store at build time.

## Project Structure

```
├── docker/
│   ├── claude-code.dockerfile       # Claude Code container image
│   ├── opencode.dockerfile          # OpenCode container image
│   ├── codex.dockerfile             # Codex container image
│   ├── claude-code-entrypoint.sh    # Validates auth + workspace, launches claude
│   ├── opencode-entrypoint.sh       # Validates credentials, launches opencode
│   ├── codex-entrypoint.sh          # Validates workspace, launches codex
│   └── pi-entrypoint.sh             # Validates workspace, launches pi
├── scripts/
│   ├── create-claude-code-factory.py  # Creates a Claude Code factory container
│   ├── create-opencode-factory.py     # Creates an OpenCode factory container
│   ├── create-codex-factory.py        # Creates a Codex factory container
│   └── create-pi-factory.py           # Creates a Pi factory container
├── skills/                          # Custom skills mounted into every container
├── ssl-certs/                       # Extra SSL certificates for corporate networks
├── docker-bake.hcl                  # Buildx targets for all images
├── claude-code-factory.json         # Claude Code auth file (gitignored)
├── opencode-factory-auth.json       # OpenCode auth file (gitignored)
└── configs/
    └── pi-models.json               # Pi model configuration
```
