#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Services Module
#
# Responsável por coletar informações dos serviços do sistema.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_SERVICES_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_SERVICES_LOADED=1

#===============================================================================
# SYSTEMD DISPONÍVEL
#===============================================================================

services_has_systemd() {

    command_exists systemctl

}

#===============================================================================
# STATUS DE UM SERVIÇO
#===============================================================================

services_status() {

    local service="$1"

    if ! services_has_systemd; then
        printf "Não suportado"
        return
    fi

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        printf "Ativo"
        return
    fi

    if systemctl list-unit-files 2>/dev/null |
        grep -q "^${service}\.service"; then

        printf "Instalado (Inativo)"
        return

    fi

    printf "Não instalado"

}

#===============================================================================
# SYSTEMD
#===============================================================================

services_systemd_status() {

    local status="Não"

    if services_has_systemd; then
        status="Sim"
    fi

    printf "Systemd..............: %s\n" "$status"

}

#===============================================================================
# SERVIÇOS ATIVOS
#===============================================================================

services_active() {

    local active="Desconhecido"

    if services_has_systemd; then

        active="$(
            systemctl list-units \
                --type=service \
                --state=running \
                --no-legend 2>/dev/null |
            wc -l
        )"

    fi

    printf "Serviços Ativos......: %s\n" "$active"

}

#===============================================================================
# SERVIÇOS FALHOS
#===============================================================================

services_failed() {

    local failed="Desconhecido"

    if services_has_systemd; then

        failed="$(
            systemctl list-units \
                --type=service \
                --state=failed \
                --no-legend 2>/dev/null |
            wc -l
        )"

    fi

    printf "Serviços Falhos......: %s\n" "$failed"

}

#===============================================================================
# SSH
#===============================================================================

services_ssh() {

    printf "SSH..................: %s\n" \
        "$(services_status ssh)"

}

#===============================================================================
# CRON
#===============================================================================

services_cron() {

    printf "Cron.................: %s\n" \
        "$(services_status cron)"

}

#===============================================================================
# NETWORKMANAGER
#===============================================================================

services_networkmanager() {

    printf "NetworkManager.......: %s\n" \
        "$(services_status NetworkManager)"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

services_run() {

    info "Coletando informações dos serviços..."

    echo

    services_systemd_status
    services_active
    services_failed
    services_ssh
    services_cron
    services_networkmanager

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
