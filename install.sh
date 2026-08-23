#!/bin/bash

# =========================================================
# Instalação - Controle de Monitores
# =========================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "Instalando Controle de Monitores..."

# Criar diretórios
mkdir -p "$BIN_DIR"
mkdir -p "$AUTOSTART_DIR"
mkdir -p "$SYSTEMD_DIR"

# Copiar scripts
cp "$SCRIPT_DIR/src/controle-monitor.sh" "$BIN_DIR/controle-monitor"
chmod +x "$BIN_DIR/controle-monitor"

cp "$SCRIPT_DIR/src/tray-icon.py" "$BIN_DIR/controle-monitor-tray"
chmod +x "$BIN_DIR/controle-monitor-tray"

cp "$SCRIPT_DIR/src/monitor-autoconfig.sh" "$BIN_DIR/monitor-autoconfig"
chmod +x "$BIN_DIR/monitor-autoconfig"

# Copiar systemd service
cp "$SCRIPT_DIR/src/monitor-autoconfig.service" "$SYSTEMD_DIR/monitor-autoconfig.service"

# Verificar se ~/.local/bin está no PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Adicionando $BIN_DIR ao PATH..."
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    echo "Execute: source ~/.bashrc"
fi

# Habilitar systemd user service
echo "Habilitando serviço systemd..."
systemctl --user daemon-reload
systemctl --user enable monitor-autoconfig.service

# Configurar atalhos de teclado via gsettings (Cinnamon/GNOME)
if command -v gsettings &> /dev/null; then
    echo "Configurando atalhos de teclado globais..."
    
    # Criar custom keybindings
    gsettings set org.cinnamon.desktop.keybindings custom-list "['ctrl-shift-1', 'ctrl-shift-2', 'ctrl-shift-3']" 2>/dev/null || \
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-3/']" 2>/dev/null || true
    
    # Configurar cada atalho (GNOME)
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-1/ name 'Alternar tela notebook' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-1/ command 'controle-monitor notebook-toggle' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-1/ binding '<Control><Shift>1' 2>/dev/null || true
    
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-2/ name 'Alternar monitor externo' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-2/ command 'controle-monitor external-toggle' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-2/ binding '<Control><Shift>2' 2>/dev/null || true
    
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-3/ name 'Alternância inteligente' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-3/ command 'controle-monitor toggle-both' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ctrl-shift-3/ binding '<Control><Shift>3' 2>/dev/null || true
    
    # Configurar atalhos (Cinnamon)
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-1/ name 'Alternar tela notebook' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-1/ command 'controle-monitor notebook-toggle' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-1/ binding "['<Control><Shift>1']" 2>/dev/null || true
    
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-2/ name 'Alternar monitor externo' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-2/ command 'controle-monitor external-toggle' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-2/ binding "['<Control><Shift>2']" 2>/dev/null || true
    
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-3/ name 'Alternância inteligente' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-3/ command 'controle-monitor toggle-both' 2>/dev/null || true
    gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/ctrl-shift-3/ binding "['<Control><Shift>3']" 2>/dev/null || true
    
    echo "Atalhos configurados (GNOME/Cinnamon):"
    echo "  Ctrl+Shift+1: Alternar tela notebook"
    echo "  Ctrl+Shift+2: Alternar monitor externo"
    echo "  Ctrl+Shift+3: Alternância inteligente"
fi

# Verificar dependências
echo ""
echo "Verificando dependências..."

MISSING_DEPS=()

if ! command -v xrandr &> /dev/null; then
    MISSING_DEPS+=("x11-xserver-utils")
fi

if ! command -v ddcutil &> /dev/null; then
    MISSING_DEPS+=("ddcutil")
fi

if ! command -v notify-send &> /dev/null; then
    MISSING_DEPS+=("libnotify-bin")
fi

if ! python3 -c "import gi; gi.require_version('AppIndicator3', '0.1')" 2>/dev/null; then
    MISSING_DEPS+=("gir1.2-appindicator3-0.1")
fi

if ! python3 -c "from Xlib import display" 2>/dev/null; then
    MISSING_DEPS+=("python3-xlib")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "Dependências faltando: ${MISSING_DEPS[*]}"
    echo "Instale com: sudo apt install ${MISSING_DEPS[*]}"
else
    echo "Todas as dependências encontradas."
fi

echo ""
echo "Instalação concluída!"
echo ""
echo "Componentes instalados:"
echo "  ~/.local/bin/controle-monitor       # CLI para controle manual"
echo "  ~/.local/bin/controle-monitor-tray  # Tray icon com ícone de monitor"
echo "  ~/.local/bin/monitor-autoconfig     # Auto-config no boot (systemd)"
echo ""
echo "Para iniciar o tray icon agora:"
echo "  controle-monitor-tray &"
echo ""
echo "Atalhos globais (funcionam sem o tray icon):"
echo "  Ctrl+Shift+1: Alternar tela notebook"
echo "  Ctrl+Shift+2: Alternar monitor externo"
echo "  Ctrl+Shift+3: Alternância inteligente"
echo ""
echo "Auto-config no boot: habilitado via systemd"
echo ""
echo "Para testar:"
echo "  controle-monitor --help"