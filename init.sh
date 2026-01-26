#!/usr/bin/env bash

# ############################################################
# Air-gapped environment provision script
# ############################################################

set -euo pipefail

# ============================================================
# Install required packages
echo "[*] Updating package list and installing required packages..."
sudo apt update && sudo apt install -y \
  gnupg \
  gnupg-agent \
  pinentry-curses \
  yubikey-manager yubico-piv-tool \
  libfido2-1 libfido2-dev libfido2-doc fido2-tools \
  pcscd \
  scdaemon \
  vim

# ============================================================
# Enable service
echo "[*] Enabling and starting pcscd service..."
sudo systemctl enable --now pcscd

# ============================================================
# Prepare GPG environment
echo "[*] Initializing GPG keyring..."
gpg --list-keys > /dev/null

echo "[*] Configuring gpg-agent..."
cat <<'EOF' > ~/.gnupg/gpg-agent.conf
# Set pinentry timeout to 86400 seconds (24 hours) to avoid timeout when entering passphrase.
# Note: setting timeout to 0 sometimes does not work as expected.
pinentry-timeout 86400
pinentry-program /usr/bin/pinentry-curses
EOF

echo "[*] Reloading gpg-agent..."
gpgconf --kill gpg-agent scdaemon

# ============================================================
# Ensure air-gapped environment
echo "[*] Confirm air-gapped environment..."
while true; do
    read -r -p "Make sure you unplug all cables and type YES: " ans
    if [[ "$ans" == "YES" ]]; then
        break
    fi
done

echo "[*] Soft Blocking all radios (WiFi, Bluetooth)..."
rfkill block all

echo "[*] Hard blocking bluetooth..."
sudo systemctl disable --now bluetooth
sudo modprobe -r btusb btrtl bnep rfcomm bluetooth

echo "[*] Hard blocking network..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw enable

nmcli networking off
sleep 1

sudo systemctl disable --now NetworkManager
sudo modprobe -r iwlwifi
sleep 1

echo "[*] Verifying network is down..."
if ping -q -c1 1.1.1.1 &>/dev/null; then
    echo "[!] Network is still reachable!"
    exit 1
else
    echo "[*] Network is successfully disabled."
fi

echo "[*] Air-gapped environment setup complete."
