#!/bin/bash
# Start CRD for local session (display :0)
# Usage: start-crd-local.sh

echo "0" > ~/.config/crd-session-mode
exec /opt/google/chrome-remote-desktop/start-active.sh
