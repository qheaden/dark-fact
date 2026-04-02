#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys



DEFAULT_CONFIG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "configs")
DEFAULT_CLAUDE_JSON = os.path.join(DEFAULT_CONFIG_DIR, "claude-code-factory.json")


def main():
    parser = argparse.ArgumentParser(description="Launch a Claude Code factory container.")
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
        "--claude-json",
        default=DEFAULT_CLAUDE_JSON,
        help="Path to the claude JSON data file holding login info (default: ../claude-code-factory.json relative to this script).",
    )
    parser.add_argument(
        "--skills-dir",
        default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills"),
        help="Path to the skills directory to mount into the container (default: ../skills relative to this script).",
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
    claude_json_path = os.path.abspath(args.claude_json)
    skills_dir_path = os.path.abspath(args.skills_dir)

    if not os.path.exists(workspace_path):
        print(f"Creating workspace directory at {workspace_path}")
        os.makedirs(workspace_path)

    if not os.path.exists(claude_json_path):
        print(f"Creating empty claude JSON file at {claude_json_path}")
        with open(claude_json_path, "w") as f:
            f.write("{}")

    cmd = [
        "docker", "create",
        "--name", args.name,
        "-v", f"{workspace_path}:/workspace",
        "-v", f"{claude_json_path}:/home/claude/.claude.json",
        "-v", f"{skills_dir_path}:/home/claude/.claude/skills",
        "-v", "dark-fact-claude-code-data:/home/claude/.claude",
        "-i", "-t",
    ]

    if args.ports:
        for port in args.ports:
            cmd.extend(["-p", port])

    if args.dns_servers:
        for dns_server in args.dns_servers:
            cmd.extend(["--dns", dns_server])

    cmd.extend([
        "df-claude-code",
        "--allow-dangerously-skip-permissions",
    ])

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print(f"Container created. Run it with: docker start -ia {args.name}")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
