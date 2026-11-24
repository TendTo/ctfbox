#!/usr/bin/env python3
"""Generate ansible/inventory.yml after applying terraform/openstack."""

import json
import os
from pathlib import Path
import subprocess

import yaml


ANSIBLE_DIR = Path(__file__).resolve().parent
TERRAFORM_DIR = ANSIBLE_DIR.parent / "terraform" / "openstack"
OUTPUT_NAMES = (
    "private_key_vulnbox",
    "private_key_server",
    "public_ip_server",
    "public_ip_vulnbox",
)


def main() -> None:
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=TERRAFORM_DIR,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        raise RuntimeError(f"Terraform output failed: {error.stderr.strip()}") from error

    terraform_outputs = json.loads(result.stdout)
    missing_outputs = [name for name in OUTPUT_NAMES if name not in terraform_outputs]
    if missing_outputs:
        raise ValueError(f"Missing Terraform outputs: {', '.join(missing_outputs)}")

    outputs = {name: terraform_outputs[name]["value"] for name in OUTPUT_NAMES}
    inventory_path = ANSIBLE_DIR / "inventory.yml.example"
    inventory = yaml.safe_load(inventory_path.read_text(encoding="utf-8"))

    vulnbox_hosts = inventory["all"]["children"]["vulnbox"]["hosts"]
    server_host = inventory["all"]["hosts"]["server"]
    vulnbox_ips = outputs["public_ip_vulnbox"]
    vulnbox_keys = outputs["private_key_vulnbox"]
    if len(vulnbox_hosts) != len(vulnbox_ips) or len(vulnbox_hosts) != len(vulnbox_keys):
        raise ValueError("Vulnbox inventory hosts do not match Terraform output counts")

    def key_path(host: dict) -> Path:
        path = Path(host["ansible_ssh_private_key_file"])
        if path.is_absolute():
            raise ValueError("SSH key paths in the inventory template must be relative")
        resolved = (ANSIBLE_DIR / path).resolve()
        try:
            resolved.relative_to(ANSIBLE_DIR)
        except ValueError as error:
            raise ValueError("SSH key paths must stay inside the ansible directory") from error
        return resolved

    key_files = []
    for (host_name, host), ip, key in zip(
        vulnbox_hosts.items(), vulnbox_ips, vulnbox_keys
    ):
        if not isinstance(ip, str) or not isinstance(key, str):
            raise ValueError(f"Invalid Terraform values for {host_name}")
        host["ansible_host"] = ip
        key_files.append((key_path(host), key))

    if not isinstance(outputs["public_ip_server"], str) or not isinstance(
        outputs["private_key_server"], str
    ):
        raise ValueError("Invalid Terraform values for server")
    server_host["ansible_host"] = outputs["public_ip_server"]
    key_files.append((key_path(server_host), outputs["private_key_server"]))

    for path, key in key_files:
        with path.open("w", encoding="utf-8") as key_file:
            os.fchmod(key_file.fileno(), 0o600)
            key_file.write(key.rstrip() + "\n")

    output_path = ANSIBLE_DIR / "inventory.yml"
    output_path.write_text(
        yaml.safe_dump(inventory, sort_keys=False),
        encoding="utf-8",
    )
    print(f"Generated {output_path}")


if __name__ == "__main__":
    main()
