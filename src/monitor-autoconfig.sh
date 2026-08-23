#!/usr/bin/env bash

# =========================================================
# Monitor Auto-Config - System Service
# =========================================================
# Garante que monitores estejam configurados corretamente no boot
# Executa como systemd user service
# =========================================================

set -euo pipefail

NOTEBOOK_OUTPUT="eDP-1"
EXTERNAL_OUTPUT="HDMI-1-0"
LOG_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/monitor-autoconfig.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

run_xrandr() {
    local cmd="$1"
    log "Executando: $cmd"
    if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log "Sucesso: $cmd"
        return 0
    else
        log "ERRO: $cmd"
        return 1
    fi
}

is_monitor_active() {
    local output="$1"
    xrandr --listmonitors 2>/dev/null | grep -q "$output"
}

get_monitor_position() {
    local output="$1"
    xrandr --query 2>/dev/null | awk -v out="$output" '
        $0 ~ out && /connected/ {
            match($0, /([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9+)]/, a)
            if (a[1] != "") print a[3] "+" a[4]
        }
    '
}

is_mirror_mode() {
    local nb_pos ext_pos
    nb_pos=$(get_monitor_position "$NOTEBOOK_OUTPUT")
    ext_pos=$(get_monitor_position "$EXTERNAL_OUTPUT")
    
    [[ -n "$nb_pos" && -n "$ext_pos" && "$nb_pos" == "$ext_pos" ]]
}

is_external_connected() {
    xrandr --query 2>/dev/null | grep -q "$EXTERNAL_OUTPUT connected"
}

notify_user() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    
    # Tenta notificar via notify-send se disponível
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -t 5000 "$title" "$message" 2>/dev/null || true
    fi
    
    log "NOTIFICAÇÃO: $title - $message"
}

main() {
    log "=== Iniciando verificação de monitores ==="
    
    # Aguarda X11/DRM estar pronto
    sleep 5
    
    local nb_on ext_on ext_connected action_taken=false message=""
    
    nb_on=$(is_monitor_active "$NOTEBOOK_OUTPUT" && echo true || echo false)
    ext_on=$(is_monitor_active "$EXTERNAL_OUTPUT" && echo true || echo false)
    ext_connected=$(is_external_connected && echo true || echo false)
    
    log "Estado inicial: notebook=$nb_on, externo=$ext_on, conectado=$ext_connected"
    
    if [[ "$ext_connected" != "true" ]]; then
        # Monitor externo não conectado fisicamente
        if [[ "$nb_on" != "true" ]]; then
            run_xrandr "xrandr --output $NOTEBOOK_OUTPUT --auto"
            action_taken=true
            message="Monitor externo não detectado. Monitor do notebook ativado."
        else
            message="Monitor externo não detectado. Monitor do notebook já ativo."
        fi
        action_taken=true
    
    elif [[ "$nb_on" != "true" && "$ext_on" != "true" ]]; then
        # Ambos desligados
        run_xrandr "xrandr --output $NOTEBOOK_OUTPUT --auto --output $EXTERNAL_OUTPUT --auto --right-of $NOTEBOOK_OUTPUT"
        action_taken=true
        message="Ambos monitores estavam desligados. Configuração estendida aplicada."
    
    elif [[ "$nb_on" != "true" ]]; then
        # Notebook desligado
        run_xrandr "xrandr --output $NOTEBOOK_OUTPUT --auto --output $EXTERNAL_OUTPUT --auto --right-of $NOTEBOOK_OUTPUT"
        action_taken=true
        message="Monitor do notebook estava desligado. Ligado e configurado em modo estendido."
    
    elif [[ "$ext_on" != "true" ]]; then
        # Externo desligado
        run_xrandr "xrandr --output $EXTERNAL_OUTPUT --auto --right-of $NOTEBOOK_OUTPUT"
        action_taken=true
        message="Monitor externo estava desligado. Ligado e configurado em modo estendido."
    
    else
        # Ambos ligados - verifica mirror
        if is_mirror_mode; then
            run_xrandr "xrandr --output $NOTEBOOK_OUTPUT --auto --output $EXTERNAL_OUTPUT --auto --right-of $NOTEBOOK_OUTPUT"
            action_taken=true
            message="Monitores estavam em modo espelho. Reconfigurado para modo estendido."
        else
            log "Monitores já configurados corretamente (modo estendido)"
            message="Monitores já configurados corretamente."
        fi
    fi
    
    if [[ "$action_taken" == "true" && -n "$message" ]]; then
        notify_user "Configuração de Monitores" "$message"
    fi
    
    log "=== Verificação concluída ==="
}

main "$@"