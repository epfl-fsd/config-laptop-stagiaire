#!/usr/bin/env bash
# Source: https://gist.github.com/ponsfrilus/970db330c857285e40bb04954e554965
# Usage (as root):
# - bash <(curl -s https://raw.githubusercontent.com/epfl-fsd/config-laptop-stagiaire/main/install.sh)
# - wget -O - https://raw.githubusercontent.com/epfl-fsd/config-laptop-stagiaire/main/install.sh | bash
# Note: use $(cat /proc/sys/kernel/random/uuid | cut -d'-' -f1) to bypass GitHub cache

# Ensure script ran as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

# User account data
NEW_USER="stage"
NEW_PASSWORD="superpassword" # 8 chars min

echo "Installation script for trainee latptop"

# Update everything
apt update && apt upgrade -y

# Ensure Wifi is on eduroam
nmcli d wifi connect eduroam

# Codium archive repo
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
  | gpg --dearmor \
  | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo -e 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' \
  | tee /etc/apt/sources.list.d/vscodium.sources

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
  openssh-server \
  sl \
  tmux \
  vim \
  vlc \
  zsh;

# Remove the "Welcome to Ubuntu"
apt remove \
  gnome-initial-setup;

# Enable SSH
systemctl enable ssh --now

# Add some SSH user
ssh-import-id gh:ponsfrilus gh:lvenries gh:evinne8 gh:antoinefabr

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

# Add a new user
if ! id "$NEW_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$NEW_USER"
fi
# Change its password
echo "$NEW_USER:$NEW_PASSWORD" | chpasswd
# Change its shell
usermod -s /bin/bash "$NEW_USER"
# Add it to the docker group
usermod -aG docker "$NEW_USER"

# Set automatic login to the new user
sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' /etc/gdm3/custom.conf
sed -i "s/^.*AutomaticLogin = .*/AutomaticLogin = $NEW_USER/" /etc/gdm3/custom.conf

# Check if stage-challenge host exist, else append entry
grep -q "stage-challenge.epfl.ch" /etc/hosts || \
sed -i "s/^127.0.0.1.*/& stage-challenge.epfl.ch/" /etc/hosts

# Ensure the challenge is running
# See https://github.com/lvenries/stage_challenge
docker rm -f stage-challenge || true
docker run -d \
  -p 80:80 \
  -p 2222:22 \
  --restart always \
  --name stage-challenge \
  ghcr.io/lvenries/stage_challenge:1.0.0

# Ask to reboot the machine
read -r -p "Reboot the machine? [Y/n] " a; [[ ${a:-Y} =~ ^[Yy] ]] && reboot
