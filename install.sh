#!/bin/bash
set -e

USERNAME="${SUDO_USER:-$(whoami)}"
USER_HOME=$(eval echo "~$USERNAME")
USER_UID=$(id -u "$USERNAME")
USER_GROUP=$(id -gn "$USERNAME")

CONFIG_DIR="$USER_HOME/.config/chrome-remote-desktop"
CONFIG_FILE=$(ls "$CONFIG_DIR"/host#*.json 2>/dev/null | head -1)

if [ -z "$CONFIG_FILE" ]; then
    echo "ERROR: CRD config not found. Register host first:"
    echo "  /opt/google/chrome-remote-desktop/start-host --code='YOUR_CODE' --redirect-url='https://remotedesktop.google.com/_/oauthredirect' --name=\$(hostname)"
    exit 1
fi

echo "User: $USERNAME"
echo "Config: $CONFIG_FILE"
echo ""

# Stop existing services
systemctl stop chrome-remote-desktop@"$USERNAME" 2>/dev/null || true
systemctl stop chrome-remote-desktop-"$USERNAME" 2>/dev/null || true
systemctl disable chrome-remote-desktop@"$USERNAME" 2>/dev/null || true

# Apply patch
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/patches/apply-patch.py"

# Install start-active.sh (virtual mode wrapper)
sed -e "s|<YOUR_USER_HOME>|$USER_HOME|g" \
    -e "s|<YOUR_USERNAME>|$USERNAME|g" \
    -e "s|<YOUR_UID>|$USER_UID|g" \
    -e "s|<YOUR_CONFIG_PATH>|$CONFIG_FILE|g" \
    "$SCRIPT_DIR/scripts/start-crd-clean.sh" > /opt/google/chrome-remote-desktop/start-active.sh
chmod +x /opt/google/chrome-remote-desktop/start-active.sh

# Install crd-mode
sed -e "s|<YOUR_USERNAME>|$USERNAME|g" \
    "$SCRIPT_DIR/scripts/crd-mode.sh" > /usr/local/bin/crd-mode
chmod +x /usr/local/bin/crd-mode

# Install session script
cp "$SCRIPT_DIR/scripts/.chrome-remote-desktop-session" "$USER_HOME/.chrome-remote-desktop-session"
chmod +x "$USER_HOME/.chrome-remote-desktop-session"
chown "$USERNAME":"$USER_GROUP" "$USER_HOME/.chrome-remote-desktop-session"

# Install systemd service
sed -e "s|<YOUR_USERNAME>|$USERNAME|g" \
    "$SCRIPT_DIR/systemd/chrome-remote-desktop.service" > /etc/systemd/system/chrome-remote-desktop-"$USERNAME".service

# Sudoers for passwordless crd-mode
cat > /etc/sudoers.d/crd-mode << SUDOERS
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart chrome-remote-desktop-$USERNAME, /usr/bin/systemctl start chrome-remote-desktop-$USERNAME, /usr/bin/systemctl stop chrome-remote-desktop-$USERNAME, /usr/bin/systemctl status chrome-remote-desktop-$USERNAME
SUDOERS
chmod 440 /etc/sudoers.d/crd-mode

systemctl daemon-reload
systemctl enable chrome-remote-desktop-"$USERNAME"
systemctl start chrome-remote-desktop-"$USERNAME"

echo ""
echo "Instalado! Acesse: https://remotedesktop.google.com/access"
echo ""
echo "Modo:    crd-mode [-v|-l|-t|-s|-h]"
echo "Serviço: systemctl [status|restart|stop] chrome-remote-desktop-$USERNAME"
