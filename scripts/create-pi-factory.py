#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys


DEFAULT_SKILLS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills")
DEFAULT_CONFIGS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "configs")


def main():
    parser = argparse.ArgumentParser(description="Launch a Pi factory container.")
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
        "--skills-dir",
        default=DEFAULT_SKILLS_DIR,
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
    skills_dir_path = os.path.abspath(args.skills_dir)
    pi_models_json = os.path.join(os.path.abspath(DEFAULT_CONFIGS_DIR), "pi-models.json")

    if not os.path.exists(workspace_path):
        print(f"Creating workspace directory at {workspace_path}")
        os.makedirs(workspace_path)

    if not os.path.exists(pi_models_json):
        print(f"Creating empty Pi models config at {pi_models_json}")
        with open(pi_models_json, "w") as f:
            f.write('{\n  "providers": {}\n}\n')

    cmd = [
        "docker", "create",
        "--name", args.name,
        "-v", f"{workspace_path}:/workspace",
        "-v", f"{skills_dir_path}:/home/pi/.pi/agent/skills",
        "-v", f"{pi_models_json}:/home/pi/.pi/agent/models.json",
        "-v", "dark-fact-pi-data:/home/pi/.pi/agent",
        "-i", "-t",
    ]

    if args.ports:
        for port in args.ports:
            cmd.extend(["-p", port])

    if args.dns_servers:
        for dns_server in args.dns_servers:
            cmd.extend(["--dns", dns_server])

    cmd.extend([
        "df-pi"
    ])

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print(f"Container created. Run it with: docker start -ia {args.name}")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
