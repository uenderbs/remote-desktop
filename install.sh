#!/bin/bash

# =========================================================
# Instalação - Controle de Monitores
# =========================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "Instalando Controle de Monitores..."

# Criar diretório bin
mkdir -p "$BIN_DIR"

# Copiar scripts
cp "$SCRIPT_DIR/src/controle-monitor.sh" "$BIN_DIR/controle-monitor"
chmod +x "$BIN_DIR/controle-monitor"

cp "$SCRIPT_DIR/src/tray-icon.py" "$BIN_DIR/controle-monitor-tray"
chmod +x "$BIN_DIR/controle-monitor-tray"

# Verificar se ~/.local/bin está no PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Adicionando $BIN_DIR ao PATH..."
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    echo "Execute: source ~/.bashrc"
fi

# Configurar inicialização automática
echo "Configurando inicialização automática..."
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/controle-monitor.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Controle de Monitores
Comment=Controle de monitores notebook/externo
Exec=$BIN_DIR/controle-monitor-tray
Icon=display-display-symbolic
Terminal=false
Categories=Utility;
EOF

echo "Ícone de bandeja configurado para iniciar com o sistema"

# Verificar dependências
echo ""
echo "Verificando dependências..."

if ! command -v xrandr &> /dev/null; then
    echo "AVISO: xrandr não encontrado. Instale com: sudo apt install x11-xserver-utils"
fi

if ! command -v ddcutil &> /dev/null; then
    echo "AVISO: ddcutil não encontrado. Para controle DDC/CI: sudo apt install ddcutil"
fi

echo ""
echo "Instalação concluída!"
echo ""
echo "Para iniciar o ícone de bandeja agora:"
echo "  controle-monitor-tray &"
echo ""
echo "Atalhos de teclado (via ícone de bandeja):"
echo "  Ctrl+Alt+1: Alternar tela notebook"
echo "  Ctrl+Alt+2: Alternar monitor externo"
echo "  Ctrl+Alt+3: Alternância inteligente"
echo ""
echo "Para iniciar manualmente:"
echo "  controle-monitor --help"
