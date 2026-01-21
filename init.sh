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
  yubikey-manager \
  pcscd \
  scdaemon

# ============================================================
# Enable pcscd service
echo "[*] Enabling and starting pcscd service..."
sudo systemctl enable --now pcscd

# ============================================================
# Prepare GPG environment
echo "[*] Initializing GPG keyring..."
gpg --list-keys > /dev/null

echo "[*] Configuring gpg-agent to use pinentry-curses with no timeout..."
cat <<'EOF' > ~/.gnupg/gpg-agent.conf
# Disable pinentry timeout so passphrase prompt waits indefinitely
pinentry-program /usr/bin/pinentry-curses --timeout 0
EOF

echo "[*] Setting pinentry-curses as the default pinentry program..."
sudo update-alternatives --set pinentry /usr/bin/pinentry-curses

echo "[*] Reloading gpg-agent..."
gpgconf --kill gpg-agent

# ============================================================
# Ensure air-gapped environment
echo "[*] Confirm air-gapped environment..."
while true; do
    read -r -p "Make sure you unplug all cables and type YES: " ans
    if [[ "$ans" == "YES" ]]; then
        break
    fi
done

echo "[*] Blocking all radios (WiFi, Bluetooth)..."
rfkill block all

echo "[*] Disabling all networking via NetworkManager..."
nmcli networking off

echo "[*] Air-gapped environment setup complete."
