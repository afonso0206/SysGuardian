#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# System Module
#
# Responsável por coletar informações gerais do sistema.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_SYSTEM_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_SYSTEM_LOADED=1

#===============================================================================
# HOSTNAME
#===============================================================================

system_hostname() {

    printf "Hostname.............: %s\n" "$(hostname)"

}

#===============================================================================
# SISTEMA OPERACIONAL
#===============================================================================

system_os() {

    printf "Sistema..............: %s\n" "$(detect_os)"

}

#===============================================================================
# KERNEL
#===============================================================================

system_kernel() {

    printf "Kernel...............: %s\n" "$(uname -r)"

}

#===============================================================================
# ARQUITETURA
#===============================================================================

system_architecture() {

    printf "Arquitetura..........: %s\n" "$(uname -m)"

}

#===============================================================================
# UPTIME
#===============================================================================

system_uptime() {

    local uptime_info="Desconhecido"

    if command_exists uptime; then
        uptime_info="$(uptime -p 2>/dev/null || echo "Desconhecido")"
    fi

    printf "Uptime...............: %s\n" "$uptime_info"

}

#===============================================================================
# DATA E HORA
#===============================================================================

system_datetime() {

    printf "Data/Hora............: %s\n" \
        "$(date '+%d/%m/%Y %H:%M:%S')"

}

#===============================================================================
# USUÁRIO
#===============================================================================

system_user() {

    printf "Usuário..............: %s\n" \
        "${SUDO_USER:-${USER:-Desconhecido}}"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

system_run() {

    info "Coletando informações do sistema..."

    echo

    system_hostname
    system_os
    system_kernel
    system_architecture
    system_uptime
    system_datetime
    system_user

    echo

}

#===============================================================================
# PROTEÇÃO CONTRA EXECUÇÃO DIRETA
#===============================================================================

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then

    printf "\n"

    printf "Este módulo faz parte do SysGuardian.\n"
    printf "Execute o programa principal em vez deste arquivo.\n"

    exit 1

fi

#===============================================================================
# FIM DO MÓDULO
#===============================================================================
