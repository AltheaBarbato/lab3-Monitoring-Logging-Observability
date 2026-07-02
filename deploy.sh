#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ANSIBLE_ROLES_PATH="$SCRIPT_DIR/ansible/roles"
INVENTORY="ansible/inventory.ini"
PLAYBOOK="ansible/site.yml"

if [[ "$1" == "--check" ]]; then
    ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --check --diff
else
    ansible-playbook -i "$INVENTORY" "$PLAYBOOK"
fi
