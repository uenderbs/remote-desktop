#!/bin/bash
SERVICE="chrome-remote-desktop-<YOUR_USERNAME>"
FLAG="$HOME/.config/crd-session-mode"

current() {
  [ -f "$FLAG" ] && echo "LOCAL (display :0)" || echo "VIRTUAL (Xvfb)"
}

status() {
  echo "=== CRD ==="
  echo "Serviço: $(systemctl is-active "$SERVICE" 2>&1)"
  echo "Modo: $(current)"
}

usage() {
  echo "Uso: crd-mode [opção]"
  echo ""
  echo "Opções:"
  echo "  -l, -local     Conectar à sessão local (display :0)"
  echo "  -v, -virtual   Iniciar sessão virtual (Xvfb)"
  echo "  -t, -toggle    Alternar entre local ↔ virtual"
  echo "  -s, -status    Ver status do serviço e modo atual"
  echo "  -h, -help      Esta ajuda"
  echo ""
  echo "Sem argumentos: menu interativo"
  echo ""
  echo "Modo atual: $(current)"
}

case "${1:-}" in
  -v|-virtual)
    rm -f "$FLAG"
    sudo systemctl restart "$SERVICE"
    echo "Virtual session (Xvfb) ativo."
    ;;
  -l|-local)
    echo "0" > "$FLAG"
    sudo systemctl restart "$SERVICE"
    echo "Local session (display :0) ativo."
    ;;
  -s|-status)
    status
    ;;
  -t|-toggle)
    if [ -f "$FLAG" ]; then
      rm -f "$FLAG"
      sudo systemctl restart "$SERVICE"
      echo "Alternado para Virtual (Xvfb)."
    else
      echo "0" > "$FLAG"
      sudo systemctl restart "$SERVICE"
      echo "Alternado para Local (display :0)."
    fi
    ;;
  -h|-help)
    usage
    ;;
  *)
    echo "=== CRD ==="
    echo "Modo atual: $(current)"
    echo ""
    echo "1 - Virtual (Xvfb)"
    echo "2 - Local (display :0)"
    echo "3 - Status"
    echo ""
    read -p "Escolha: " opt
    case "$opt" in
      1) rm -f "$FLAG"; sudo systemctl restart "$SERVICE"; echo "Virtual session (Xvfb) ativo." ;;
      2) echo "0" > "$FLAG"; sudo systemctl restart "$SERVICE"; echo "Local session (display :0) ativo." ;;
      3) status ;;
      *) echo "Opção inválida."; exit 1 ;;
    esac
    ;;
esac
