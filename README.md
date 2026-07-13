# Dark Fact

A setup for running an autonomous coding agent as a **dark factory** of software development.

The term comes from manufacturing: a "dark factory" (or "lights-out factory") is a fully automated production facility that operates without human presence. Dark Fact  applies the same idea to software — containerized AI coding agents that run autonomously on your codebase without requiring human approval at every step.

> **Warning:** Fully autonomous coding agents can be dangerous even inside a container. A compromised or misbehaving agent can still make outbound network requests, exfiltrate data, or interact with external services. This repo does not implement any network filtering — that is your responsibility. Consider pairing these containers with a network firewall or egress proxy appropriate for your threat model.

## How It Works

Each dark factory is a Docker container that:

1. Mounts a local workspace directory as `/workspace`
2. Mounts credentials so the agent can authenticate
3. Mounts a `skills/` directory so the agent has access to custom skills
4. Starts the agent with a permissive configuration to bypass approval prompts

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

The factory target can also be built explicitly:

```bash
docker buildx bake factory
```

This produces the local `dark-factory` image.

## Building a Dark Factory

### 1. Credentials (optional)

The script uses `configs/factory-auth.json` as the auth file by default. If it doesn't exist, it is created automatically as an empty file.

You can also pass API credentials directly via `--env` instead of using an auth file:

### 2. Create the container

```bash
# Using an API key
python scripts/create-factory.py /path/to/your/project \
    --name my-dark-factory \
    --env ANTHROPIC_API_KEY=sk-ant-...

# Using an auth file
python scripts/create-factory.py /path/to/your/project \
    --name my-dark-factory
```

**Options:**

| Flag | Description |
|------|-------------|
| `workspace-path` | (required) Path to the project directory to mount as `/workspace` |
| `--name` | (required) Name for the Docker container |
| `--auth-json` | Path to the authentication JSON file (default: `configs/factory-auth.json`) |
| `--skills-dir` | Path to the skills directory (default: `skills/`) |
| `--config-json` | Path to a custom factory configuration file (auto-generated with permissive settings if omitted) |
| `--env` | Environment variable, e.g. `ANTHROPIC_API_KEY=sk-...`. Repeatable. |
| `--port` | Port mapping, e.g. `8000:8000`. Repeatable. |

### 3. Start the factory

```bash
docker start -ia my-dark-factory
```

The agent launches inside the container with full permissions pre-approved and working directory set to `/workspace`.

## Skills

The `skills/` directory is mounted into every factory container. Any skill you add there is immediately available to the running agent — no container rebuild needed.

See `skills/README.md` for details.

## SSL Certificates

If your network requires custom root certificates (e.g. a corporate proxy like ZScaler), place the `.crt` or `.pem` files in `ssl-certs/`. The Dockerfiles install any certificates found there into the container's trust store at build time.

## Project Structure

```
├── docker/
│   ├── factory.dockerfile           # Factory container image
│   ├── factory-entrypoint.sh        # Validates credentials and launches the agent
├── scripts/
│   └── create-factory.py            # Creates a factory container
├── skills/                          # Custom skills mounted into every container
├── ssl-certs/                       # Extra SSL certificates for corporate networks
├── docker-bake.hcl                  # Buildx targets for all images
└── configs/
    ├── factory-auth.json            # Authentication file (gitignored)
    └── factory-config.json          # Factory configuration (gitignored)
```
