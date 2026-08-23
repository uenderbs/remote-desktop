#!/bin/bash

# =========================================================
# Instalação - Controle de Monitores
# =========================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

echo "Instalando Controle de Monitores..."

# Criar diretório bin
mkdir -p "$BIN_DIR"

# Copiar script
cp "$SCRIPT_DIR/src/controle-monitor.sh" "$BIN_DIR/controle-monitor"
chmod +x "$BIN_DIR/controle-monitor"

# Verificar se ~/.local/bin está no PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Adicionando $BIN_DIR ao PATH..."
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    echo "Execute: source ~/.bashrc"
fi

# Configurar atalhos de teclado (Cinnamon)
if [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]]; then
    echo "Configurando atalhos de teclado..."
    
    dconf write /org/cinnamon/desktop/keybindings/custom-list "['ctrl1-notebook', 'ctrl2-external', 'ctrl3-smart']"
    
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl1-notebook/name "'Alternar tela notebook'"
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl1-notebook/command "'controle-monitor notebook-toggle'"
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl1-notebook/binding "['<Control><Alt>1']"
    
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl2-external/name "'Alternar monitor externo'"
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl2-external/command "'controle-monitor external-toggle'"
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl2-external/binding "['<Control><Alt>2']"
    
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl3-smart/name "'Alternância inteligente'"
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl3-smart/command "'controle-monitor toggle-both'"
    dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/ctrl3-smart/binding "['<Control><Alt>3']"
    
    echo "Atalhos configurados:"
    echo "  Ctrl+Alt+1: Alternar tela notebook"
    echo "  Ctrl+Alt+2: Alternar monitor externo"
    echo "  Ctrl+Alt+3: Alternância inteligente"
fi

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
echo "Execute: controle-monitor --help"
