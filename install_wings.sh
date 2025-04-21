#!/bin/bash
# Auto Installer Wings Daemon
set -e

echo "🔧 Installing Wings..."
curl -sSL https://get.pterodactyl.io/wings.sh | bash

echo "📁 Create config directory..."
sudo mkdir -p /etc/pterodactyl
cd /etc/pterodactyl

echo "⚠️  Download config.yml from Panel Node page and place it in /etc/pterodactyl/config.yml"
echo "➡️  After that, run: sudo systemctl enable --now wings"
