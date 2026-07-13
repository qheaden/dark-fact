#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys



SHARED_SKILLS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shared-skills")
KANBANS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "kanbans")

def main():
    parser = argparse.ArgumentParser(description="Create a dark factory container.")
    parser.add_argument(
        "workspace_path",
        metavar="workspace-path",
        help="Path to the working directory to mount as /workspace inside the container.",
    )
    parser.add_argument(
        "--name",
        required=True,
        help="Name of the Docker container to create.",
    )
    parser.add_argument(
        "--env",
        action="append",
        dest="env_vars",
        help="Environment variable to pass to the container (e.g., ANTHROPIC_API_KEY=sk-...). Can be used multiple times.",
    )
    parser.add_argument(
        "--port",
        action="append",
        dest="ports",
        help="Port mapping for the container (e.g., 8000:8000). Can be used multiple times.",
    )
    parser.add_argument(
        "--dns",
        action="append",
        dest="dns_servers",
        help="DNS server to use for the container (e.g., 8.8.8.8). Can be used multiple times.",
    )
    args = parser.parse_args()

    workspace_path = os.path.abspath(args.workspace_path)
    skills_dir_path = os.path.abspath(SHARED_SKILLS_DIR)
    kanban_path = os.path.join(KANBANS_DIR, args.name)

    if not os.path.exists(workspace_path):
        print(f"Creating workspace directory at {workspace_path}")
        os.makedirs(workspace_path)

    for state in (
        "1-planning",
        "2-ready-for-work",
        "3-in-progress",
        "4-in-review",
        "5-done",
        "worklogs",
    ):
        os.makedirs(os.path.join(kanban_path, state), exist_ok=True)

    volume_prefix = f"dark-factory-{args.name}"

    cmd = [
        "docker", "create",
        "--name", args.name,
        "-v", f"{workspace_path}:/workspace",
        "-v", f"{kanban_path}:/kanban",
        "-v", f"{skills_dir_path}:/home/opencode/.config/opencode/skills",
        "-v", f"{volume_prefix}-config:/home/opencode/.config/opencode",
        "-v", f"{volume_prefix}-data:/home/opencode/.local/share/opencode",
        "--add-host", "host.docker.local:host-gateway",
        "-i", "-t",
    ]

    if args.env_vars:
        for env_var in args.env_vars:
            cmd.extend(["-e", env_var])

    if args.ports:
        for port in args.ports:
            cmd.extend(["-p", port])

    if args.dns_servers:
        for dns_server in args.dns_servers:
            cmd.extend(["--dns", dns_server])

    cmd.append("dark-factory")

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print(f"Container created. Run it with: docker start -ia {args.name}")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
