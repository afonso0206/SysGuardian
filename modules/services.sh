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
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

services_has_systemd() {

    command_exists systemctl

}

services_get_status() {

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

services_get_systemd() {

    if services_has_systemd; then
        printf "Sim"
    else
        printf "Não"
    fi

}

services_get_active_count() {

    if services_has_systemd; then

        systemctl list-units \
            --type=service \
            --state=running \
            --no-legend 2>/dev/null |
        wc -l

    else

        printf "Desconhecido"

    fi

}

services_get_failed_count() {

    if services_has_systemd; then

        systemctl list-units \
            --type=service \
            --state=failed \
            --no-legend 2>/dev/null |
        wc -l

    else

        printf "Desconhecido"

    fi

}

services_get_failed_services() {

    if services_has_systemd; then

        systemctl list-units \
            --type=service \
            --state=failed \
            --no-legend 2>/dev/null

    fi

}

services_get_ssh() {

    services_get_status ssh

}

services_get_cron() {

    services_get_status cron

}

services_get_networkmanager() {

    services_get_status NetworkManager

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

services_systemd_status() {

    printf "Systemd..............: %s\n" \
        "$(services_get_systemd)"

}

services_active() {

    printf "Serviços Ativos......: %s\n" \
        "$(services_get_active_count)"

}

services_failed() {

    printf "Serviços Falhos......: %s\n" \
        "$(services_get_failed_count)"

}

services_ssh() {

    printf "SSH..................: %s\n" \
        "$(services_get_ssh)"

}

services_cron() {

    printf "Cron.................: %s\n" \
        "$(services_get_cron)"

}

services_networkmanager() {

    printf "NetworkManager.......: %s\n" \
        "$(services_get_networkmanager)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

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
