#!/bin/bash
unset DISPLAY GDK_BACKEND WAYLAND_DISPLAY XDG_SESSION_DESKTOP DESKTOP_SESSION XDG_CURRENT_DESKTOP SESSION_MANAGER XDG_SESSION_ID DBUS_SESSION_BUS_ADDRESS

export HOME=<YOUR_USER_HOME>
export USER=<YOUR_USERNAME>
export LOGNAME=<YOUR_USERNAME>
export SHELL=/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export XDG_RUNTIME_DIR=/run/user/<YOUR_UID>
export CHROME_REMOTE_DESKTOP_USE_XVFB=1

exec /opt/google/chrome-remote-desktop/chrome-remote-desktop \
    --config=<YOUR_CONFIG_PATH> \
    --start \
    --child-process
