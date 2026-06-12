#!/usr/bin/env bash
# Source: https://gist.github.com/ponsfrilus/970db330c857285e40bb04954e554965
# Usage (as root):
# - bash <(curl -s https://raw.githubusercontent.com/epfl-fsd/config-laptop-stagiaire/main/install.sh)
# - wget -O - https://raw.githubusercontent.com/epfl-fsd/config-laptop-stagiaire/main/install.sh | bash
# Note: use $(cat /proc/sys/kernel/random/uuid | cut -d'-' -f1) to bypass GitHub cache

# Ensure script is ran as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

echo "Installation script for trainee latptop"

################################################################################
# Docker installation and configuration
################################################################################
# Install Docker (https://docs.docker.com/engine/install/ubuntu/)
if docker ps >/dev/null 2>&1; then
  echo "Docker seems to be already running fine"
else
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh ./get-docker.sh
fi

# Docker post-install (https://docs.docker.com/engine/install/linux-postinstall/)
groupadd docker 2>/dev/null || true
usermod -aG docker administrator

################################################################################
# Stage challenge
################################################################################
# Check if stage-challenge host exist, else append entry
grep -q "stage-challenge.fsd.epfl.ch" /etc/hosts || \
sed -i "s/^127.0.0.1.*/& stage-challenge.fsd.epfl.ch/" /etc/hosts

# Ensure the challenge is running
# See https://github.com/lvenries/stage_challenge
docker rm -f stage-challenge || true
docker run -d \
  -p 80:80 \
  -p 2222:22 \
  --restart always \
  --name stage-challenge \
  ghcr.io/dwesh163/stage_challenge:1.1.0

################################################################################
# Ask to reboot the machine
read -p "Reboot the machine now? (y/n) " -n 1 -r < /dev/tty
echo
[[ $REPLY =~ ^[Yy]$ ]] && reboot
