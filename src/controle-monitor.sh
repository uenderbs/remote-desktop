#!/bin/bash

# =========================================================
# Controle de Monitores - Linux
# =========================================================
# Script para controle de monitores em notebooks com tela externa
# Compatível com X11 e Wayland (via xrandr)
# =========================================================

# Configurações
NOTEBOOK_OUTPUT="eDP-1"
EXTERNAL_OUTPUT="HDMI-1"

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =========================================================
# Funções auxiliares
# =========================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# =========================================================
# Funções de controle de monitores
# =========================================================

# Listar todos os monitores disponíveis
list_monitors() {
    log_info "Monitores disponíveis:"
    xrandr --listmonitors
}

# Verificar se um output está ativo
is_monitor_active() {
    local output=$1
    xrandr --listmonitors | grep -q "$output"
}

# Ativar monitor interno (notebook)
notebook_on() {
    if is_monitor_active "$NOTEBOOK_OUTPUT"; then
        log_warning "Monitor interno já está ativo"
        return 1
    fi
    
    xrandr --output "$NOTEBOOK_OUTPUT" --auto
    if [ $? -eq 0 ]; then
        log_success "Monitor interno ativado"
        return 0
    else
        log_error "Falha ao ativar monitor interno"
        return 1
    fi
}

# Desativar monitor interno (notebook)
notebook_off() {
    if ! is_monitor_active "$NOTEBOOK_OUTPUT"; then
        log_warning "Monitor interno já está desativado"
        return 1
    fi
    
    xrandr --output "$NOTEBOOK_OUTPUT" --off
    if [ $? -eq 0 ]; then
        log_success "Monitor interno desativado"
        return 0
    else
        log_error "Falha ao desativar monitor interno"
        return 1
    fi
}

# Alternar monitor interno
toggle_notebook() {
    if is_monitor_active "$NOTEBOOK_OUTPUT"; then
        notebook_off
    else
        notebook_on
    fi
}

# Verificar se algum monitor externo está ativo
external_is_any_on() {
    xrandr --listmonitors | grep -q "$EXTERNAL_OUTPUT"
}

# Ativar monitor externo
external_on() {
    if external_is_any_on; then
        log_warning "Monitor externo já está ativo"
        return 1
    fi
    
    xrandr --output "$EXTERNAL_OUTPUT" --auto
    if [ $? -eq 0 ]; then
        log_success "Monitor externo ativado"
        return 0
    else
        log_error "Falha ao ativar monitor externo"
        return 1
    fi
}

# Desativar monitor externo
external_off() {
    if ! external_is_any_on; then
        log_warning "Monitor externo já está desativado"
        return 1
    fi
    
    xrandr --output "$EXTERNAL_OUTPUT" --off
    if [ $? -eq 0 ]; then
        log_success "Monitor externo desativado"
        return 0
    else
        log_error "Falha ao desativar monitor externo"
        return 1
    fi
}

# Alternar monitor externo
toggle_external() {
    if external_is_any_on; then
        external_off
    else
        external_on
    fi
}

# Alternância inteligente entre monitores
toggle_both_smart() {
    local ext_on=$(external_is_any_on && echo "true" || echo "false")
    local nb_on=$(is_monitor_active "$NOTEBOOK_OUTPUT" && echo "true" || echo "false")
    
    if [ "$ext_on" != "$nb_on" ]; then
        # Sincroniza com UM comando
        if [ "$ext_on" = "true" ] && [ "$nb_on" = "false" ]; then
            notebook_on
        else
            notebook_off
        fi
        return
    fi
    
    # Já estão iguais -> alterna ambos juntos
    if [ "$ext_on" = "true" ] && [ "$nb_on" = "true" ]; then
        notebook_off
        external_off
    else
        notebook_on
        external_on
    fi
}

# Configurar disposition estendido
setup_extended() {
    xrandr --output "$NOTEBOOK_OUTPUT" --auto --output "$EXTERNAL_OUTPUT" --auto --right-of "$NOTEBOOK_OUTPUT"
    if [ $? -eq 0 ]; then
        log_success "Disposition estendido configurado"
    else
        log_error "Falha ao configurar disposition estendido"
    fi
}

# Configurar disposition espelho
setup_mirror() {
    xrandr --output "$NOTEBOOK_OUTPUT" --auto --output "$EXTERNAL_OUTPUT" --same-as "$NOTEBOOK_OUTPUT"
    if [ $? -eq 0 ]; then
        log_success "Disposition espelho configurado"
    else
        log_error "Falha ao configurar disposition espelho"
    fi
}

# =========================================================
# Funções DDC/CI (opcional)
# =========================================================

# Verificar se ddcutil está instalado
check_ddcutil() {
    if ! command -v ddcutil &> /dev/null; then
        log_warning "ddcutil não está instalado. Controle DDC/CI não disponível."
        log_info "Para instalar: sudo apt install ddcutil (Debian/Ubuntu)"
        return 1
    fi
    return 0
}

# Listar monitores DDC/CI
list_ddc_monitors() {
    if check_ddcutil; then
        log_info "Monitores DDC/CI detectados:"
        sudo ddcutil detect
    fi
}

# =========================================================
# Menu interativo
# =========================================================

show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Controle de Monitores - Linux${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo "1. Listar monitores"
    echo "2. Ativar monitor interno"
    echo "3. Desativar monitor interno"
    echo "4. Alternar monitor interno"
    echo "5. Ativar monitor externo"
    echo "6. Desativar monitor externo"
    echo "7. Alternar monitor externo"
    echo "8. Alternância inteligente"
    echo "9. Configurar disposition estendido"
    echo "10. Configurar disposition espelho"
    echo "11. Listar monitores DDC/CI"
    echo "0. Sair"
    echo
    echo -e "${YELLOW}Selecione uma opção: ${NC}"
}

# =========================================================
# Função principal
# =========================================================

main() {
    # Verificar se xrandr está disponível
    if ! command -v xrandr &> /dev/null; then
        log_error "xrandr não está instalado. Instale com: sudo apt install x11-xserver-utils"
        exit 1
    fi
    
    # Se argumento foi passado, executar comando diretamente
    if [ $# -gt 0 ]; then
        case $1 in
            "list") list_monitors ;;
            "notebook-on") notebook_on ;;
            "notebook-off") notebook_off ;;
            "notebook-toggle") toggle_notebook ;;
            "external-on") external_on ;;
            "external-off") external_off ;;
            "external-toggle") toggle_external ;;
            "toggle-both") toggle_both_smart ;;
            "extended") setup_extended ;;
            "mirror") setup_mirror ;;
            "ddc-list") list_ddc_monitors ;;
            *)
                log_error "Comando desconhecido: $1"
                echo "Uso: $0 [comando]"
                echo "Comandos disponíveis:"
                echo "  list              - Listar monitores"
                echo "  notebook-on       - Ativar monitor interno"
                echo "  notebook-off      - Desativar monitor interno"
                echo "  notebook-toggle   - Alternar monitor interno"
                echo "  external-on       - Ativar monitor externo"
                echo "  external-off      - Desativar monitor externo"
                echo "  external-toggle   - Alternar monitor externo"
                echo "  toggle-both       - Alternância inteligente"
                echo "  extended          - Configurar disposition estendido"
                echo "  mirror            - Configurar disposition espelho"
                echo "  ddc-list          - Listar monitores DDC/CI"
                exit 1
                ;;
        esac
        exit $?
    fi
    
    # Modo interativo
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) list_monitors ;;
            2) notebook_on ;;
            3) notebook_off ;;
            4) toggle_notebook ;;
            5) external_on ;;
            6) external_off ;;
            7) toggle_external ;;
            8) toggle_both_smart ;;
            9) setup_extended ;;
            10) setup_mirror ;;
            11) list_ddc_monitors ;;
            0) 
                log_info "Saindo..."
                exit 0
                ;;
            *)
                log_error "Opção inválida"
                ;;
        esac
        
        echo
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read -r
    done
}

# Executar função principal
main "$@"
