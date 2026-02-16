#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Step 1: Terraform — Provisioning EC2 instance ==="
cd "$SCRIPT_DIR/terraform"
terraform init
terraform apply -auto-approve

echo ""
echo "=== Waiting for instance to become reachable via SSH ==="
PUBLIC_IP=$(terraform output -raw public_ip)
for i in $(seq 1 30); do
    if ssh -i gorillas-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@"$PUBLIC_IP" "echo ready" 2>/dev/null; then
        echo "Instance is reachable."
        break
    fi
    echo "  Attempt $i/30 — waiting 10s..."
    sleep 10
done

echo ""
echo "=== Step 2: Ansible — Configuring web server ==="
cd "$SCRIPT_DIR/ansible"
ansible-playbook -i inventory.ini playbook.yml

echo ""
echo "=== Deployment complete! ==="
terraform -chdir="$SCRIPT_DIR/terraform" output
