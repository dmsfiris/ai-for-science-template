#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo bash setup-server.sh yourdomain.com admin@youremail.com
DOMAIN="${1:-}"
EMAIL="${2:-}"

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  echo "Usage: sudo bash setup-server.sh <domain> <email>"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Basic packages
apt-get update
apt-get install -y ca-certificates curl gnupg ufw

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (if not root login)
if id -nG "$SUDO_USER" | grep -qw docker; then
  echo "User already in docker group"
else
  usermod -aG docker "$SUDO_USER" || true
fi

# Firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
yes | ufw enable

# Create project directory
mkdir -p /opt/ai-for-science
chown -R "$SUDO_USER":"$SUDO_USER" /opt/ai-for-science

cat >/opt/ai-for-science/.env <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

echo "Setup complete. Re-login may be required for docker group to take effect."
