#!/usr/bin/env bash
# Source: https://gist.github.com/ponsfrilus/970db330c857285e40bb04954e554965
# Usage:
# - bash <(curl -s https://raw.githubusercontent.com/epfl-fsd/config-laptop-stagiaire/refs/heads/main/install.sh)
# - wget -O - https://raw.githubusercontent.com/epfl-fsd/config-laptop-stagiaire/refs/heads/main/install.sh | bash
# Note: use $(cat /proc/sys/kernel/random/uuid | cut -d'-' -f1) to bypass GitHub cache
NEW_USER="stage"
# set passwore more than 8
NEW_PASSWORD="superpassword"
echo "Installation script for trainee latptop"

# Update everything
apt update && apt upgrade -y

# Ensure Wifi is on eduroam
nmcli d wifi connect eduroam

# Codium archive repo
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
  | gpg --dearmor \
  | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo -e 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' \
  | sudo tee /etc/apt/sources.list.d/vscodium.sources

# Re-update for new repos
apt update

# Install usefull tools
apt install -y \
  bash-completion \
  codium \
  ca-certificates \
  curl \
  git \
  iputils-ping \
  sl \
  tmux \
  vim \
  vlc \
  zsh

# Install Docker
# See https://docs.docker.com/engine/install/ubuntu/
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh

# Docker post-install (https://docs.docker.com/engine/install/linux-postinstall/)
groupadd docker 2>/dev/null || true
usermod -aG docker administrator

# systemctl enable docker.service
# systemctl enable containerd.service
# Add a new user
if ! id "$NEW_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$NEW_USER"
fi
echo "$NEW_USER:$NEW_PASSWORD" | sudo chpasswd
sudo usermod -aG docker "$NEW_USER"

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
# setup autologin with the new user
cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $NEW_USER --noclear %I \$TERM
EOF

sudo systemctl daemon-reload

# Ensure the challenge is running
# See https://github.com/lvenries/stage_challenge
sudo docker rm -f stage-challenge || true
sudo docker run -d \
  -p 80:80 \
  -p 2222:22 \
  --restart always \
  --name stage-challenge \
  ghcr.io/lvenries/stage_challenge:1.0.0
