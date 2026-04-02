#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys



DEFAULT_AUTH_JSON = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "opencode-factory-auth.json")
DEFAULT_CONFIG_JSON = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "opencode-factory.json")
DEFAULT_SKILLS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills")

def main():
    parser = argparse.ArgumentParser(description="Launch an OpenCode factory container.")
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
        "--auth-json",
        default=DEFAULT_AUTH_JSON,
        help="Path to the OpenCode auth JSON file holding login info (default: ../opencode-factory-auth.json relative to this script).",
    )
    parser.add_argument(
        "--skills-dir",
        default=DEFAULT_SKILLS_DIR,
        help="Path to the skills directory to mount into the container (default: ../skills relative to this script).",
    )
    parser.add_argument(
        "--config-json",
        default=DEFAULT_CONFIG_JSON,
        help="Path to the opencode JSON config file to mount (default: ../opencode-factory.json relative to this script).",
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
    auth_json_path = os.path.abspath(args.auth_json)
    skills_dir_path = os.path.abspath(args.skills_dir)

    if not os.path.exists(workspace_path):
        print(f"Creating workspace directory at {workspace_path}")
        os.makedirs(workspace_path)

    if not os.path.exists(auth_json_path):
        print(f"Creating empty auth JSON file at {auth_json_path}")
        with open(auth_json_path, "w") as f:
            f.write("{}\n")

    config_json_path = os.path.abspath(args.config_json)
    if not os.path.exists(config_json_path):
        print(f"Creating empty config JSON file at {config_json_path}")
        with open(config_json_path, "w") as f:
            f.write("{}\n")

    cmd = [
        "docker", "create",
        "--name", args.name,
        "-v", f"{workspace_path}:/workspace",
        "-v", f"{auth_json_path}:/home/opencode/.local/share/opencode/auth.json",
        "-v", f"{skills_dir_path}:/home/opencode/.config/opencode/skills",
        "-v", "dark-fact-opencode-config:/home/opencode/.config/opencode",
        "-v", "dark-fact-opencode-data:/home/opencode/.local/share/opencode",
        "-i", "-t",
    ]

    cmd.extend(["-v", f"{config_json_path}:/home/opencode/.config/opencode/opencode.json"])

    if args.env_vars:
        for env_var in args.env_vars:
            cmd.extend(["-e", env_var])

    if args.ports:
        for port in args.ports:
            cmd.extend(["-p", port])

    if args.dns_servers:
        for dns_server in args.dns_servers:
            cmd.extend(["--dns", dns_server])

    cmd.append("df-opencode")

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print(f"Container created. Run it with: docker start -ia {args.name}")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
