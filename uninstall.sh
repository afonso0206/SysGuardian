#!/usr/bin/env bash
#
# ==========================================================
# SysGuardian Uninstaller
# Version : 7.0.0-alpha2
# ==========================================================

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
if [[ -f "${PROJECT_ROOT}/lib/core.sh" ]]; then
    source "${PROJECT_ROOT}/lib/core.sh"
elif [[ -f "/usr/share/sysguardian/lib/core.sh" ]]; then
    source "/usr/share/sysguardian/lib/core.sh"
else
    echo "Erro: lib/core.sh não encontrado."
    exit 1
fi

############################################
# Variáveis
############################################

PROGRAM_CMD="sysguardian"

BIN_DIR="/usr/local/bin"
DATA_DIR="/usr/share/sysguardian"
CONFIG_DIR="/etc/sysguardian"
LOG_DIR="/var/log/sysguardian"

CONFIG_FILE="$CONFIG_DIR/sysguardian.conf"

CONFIG_REMOVED="Não verificado"
LOGS_REMOVED="Não verificado"

############################################
# Erros
############################################

cleanup_on_error() {
    error "A desinstalação foi interrompida."

    echo
    echo "Revise a mensagem acima."
    exit 1
}

trap cleanup_on_error ERR

############################################
# Verificar Instalação
############################################

check_installation() {

    info "Verificando se o SysGuardian está instalado..."

    if [[ ! -f "$BIN_DIR/$PROGRAM_CMD" ]] && [[ ! -d "$DATA_DIR" ]]; then
        die "SysGuardian não está instalado."
    fi

    ok "Instalação encontrada."

}

############################################
# Remover Executável / Launcher
############################################

remove_launcher() {

    info "Removendo launcher do sistema..."

    if [[ -f "$BIN_DIR/$PROGRAM_CMD" ]]; then
        rm -f "$BIN_DIR/$PROGRAM_CMD"
        ok "Launcher '$BIN_DIR/$PROGRAM_CMD' removido."
    else
        warn "Launcher '$BIN_DIR/$PROGRAM_CMD' não encontrado."
    fi

}

############################################
# Remover Arquivos do Programa
############################################

remove_program_files() {

    info "Removendo arquivos do programa..."

    local items=(
        "$DATA_DIR/sysguardian"
        "$DATA_DIR/modules"
        "$DATA_DIR/lib"
        "$DATA_DIR/templates"
        "$DATA_DIR/README.md"
        "$DATA_DIR/LICENSE"
        "$DATA_DIR/VERSION"
    )

    for item in "${items[@]}"; do
        if [[ -e "$item" ]]; then
            if [[ -d "$item" ]]; then
                rm -rf "$item"
            else
                rm -f "$item"
            fi
        fi
    done

    ok "Arquivos principais do programa removidos."

}

############################################
# Remover Configuração
############################################

remove_configuration() {

    if [[ -f "$CONFIG_FILE" ]] || [[ -d "$CONFIG_DIR" ]]; then
        echo
        if confirm "Deseja remover os arquivos de configuração?"; then
            info "Removendo configurações..."

            if [[ -f "$CONFIG_FILE" ]]; then
                rm -f "$CONFIG_FILE"
                ok "Arquivo '$CONFIG_FILE' removido."
            fi

            if [[ -d "$CONFIG_DIR" ]]; then
                if rmdir "$CONFIG_DIR" 2>/dev/null; then
                    ok "Diretório '$CONFIG_DIR' removido."
                else
                    warn "O diretório '$CONFIG_DIR' contém outros arquivos e foi preservado."
                fi
            fi

            CONFIG_REMOVED="Sim"
        else
            warn "Arquivos de configuração preservados em '$CONFIG_DIR'."
            CONFIG_REMOVED="Não (Preservada)"
        fi
    else
        CONFIG_REMOVED="Não encontrada"
    fi

}

############################################
# Remover Logs
############################################

remove_logs() {

    if [[ -d "$LOG_DIR" ]]; then
        echo
        if confirm "Deseja remover os relatórios e logs?"; then
            info "Removendo logs e relatórios..."
            rm -rf "$LOG_DIR"
            ok "Diretório de logs '$LOG_DIR' removido."
            LOGS_REMOVED="Sim"
        else
            warn "Logs e relatórios preservados em '$LOG_DIR'."
            LOGS_REMOVED="Não (Preservados)"
        fi
    else
        LOGS_REMOVED="Não encontrados"
    fi

}

############################################
# Remover Diretórios Vazios
############################################

remove_empty_directories() {

    info "Limpando diretórios residuais..."

    rmdir "$DATA_DIR" 2>/dev/null || true
    rmdir "$CONFIG_DIR" 2>/dev/null || true
    rmdir "$LOG_DIR" 2>/dev/null || true

}

############################################
# Validação
############################################

validate_uninstall() {

    info "Validando desinstalação..."

    if command_exists "$PROGRAM_CMD"; then
        die "A desinstalação falhou. O comando '$PROGRAM_CMD' ainda está presente."
    fi

    if [[ -d "$DATA_DIR" ]]; then
        warn "Ainda existem arquivos em $DATA_DIR."
    fi

    ok "Desinstalação validada."

}

############################################
# Resumo
############################################

show_summary() {

cat <<EOF

====================================================
        Desinstalação concluída com sucesso
====================================================

Status dos componentes:

  • Launcher ($BIN_DIR/$PROGRAM_CMD): Removido
  • Arquivos ($DATA_DIR): Removidos
  • Configuração ($CONFIG_DIR): $CONFIG_REMOVED
  • Logs/Relatórios ($LOG_DIR): $LOGS_REMOVED

====================================================

EOF

}

############################################
# Main
############################################

main() {

    show_banner

    require_root

    ok "Permissões de administrador confirmadas."

    check_installation

    remove_launcher

    remove_program_files

    remove_configuration

    remove_logs

    remove_empty_directories

    validate_uninstall

    show_summary

}

main "$@"
