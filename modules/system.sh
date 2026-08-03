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
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

system_get_hostname() {

    hostname

}

system_get_os() {

    detect_os

}

system_get_kernel() {

    uname -r

}

system_get_architecture() {

    uname -m

}

system_get_uptime() {

    local uptime_info="Desconhecido"

    if command_exists uptime; then
        uptime_info="$(uptime -p 2>/dev/null || echo "Desconhecido")"
    fi

    printf "%s" "$uptime_info"

}

system_get_datetime() {

    date '+%d/%m/%Y %H:%M:%S'

}

system_get_user() {

    printf "%s" "${SUDO_USER:-${USER:-Desconhecido}}"

}

# Opcional, mas será útil para o Core na PR-003
system_get_reboot_required() {

    [[ -f /var/run/reboot-required ]]

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

system_hostname() {

    printf "Hostname.............: %s\n" \
        "$(system_get_hostname)"

}

system_os() {

    printf "Sistema..............: %s\n" \
        "$(system_get_os)"

}

system_kernel() {

    printf "Kernel...............: %s\n" \
        "$(system_get_kernel)"

}

system_architecture() {

    printf "Arquitetura..........: %s\n" \
        "$(system_get_architecture)"

}

system_uptime() {

    printf "Uptime...............: %s\n" \
        "$(system_get_uptime)"

}

system_datetime() {

    printf "Data/Hora............: %s\n" \
        "$(system_get_datetime)"

}

system_user() {

    printf "Usuário..............: %s\n" \
        "$(system_get_user)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
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
