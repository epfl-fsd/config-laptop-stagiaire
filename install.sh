#!/usr/bin/env bash
# Source: https://gist.github.com/ponsfrilus/970db330c857285e40bb04954e554965
# Usage: bash <(curl -s https://gist.githubusercontent.com/ponsfrilus/970db330c857285e40bb04954e554965/raw/install.sh)

echo "Installation script for trainee latptop"

# Update everything
apt update && apt upgrade -y

# Ensure Wifi is on eduroam
nmcli d wifi connect eduroam

# Install usefull tools
apt install -y \
  codium \
  curl \
  docker \
  git \
  iputils-ping \
  sl \
  tmux \
  vim \
  vlc \
  zsh

# Add a "stage" user
useradd -m -p "PleaseLetMeIn" "stage"

# Ensure the challenge is running
# See https://github.com/lvenries/stage_challenge
docker run -d -p 80:80 -p 2222:22 --name stage-challenge ghcr.io/lvenries/stage_challenge:1.0.0 --restart
