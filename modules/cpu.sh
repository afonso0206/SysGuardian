#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# CPU Module
#
# Responsável por coletar informações do processador.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_CPU_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_CPU_LOADED=1

#===============================================================================
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

cpu_get_model() {

    local model="Desconhecido"

    if file_exists "/proc/cpuinfo"; then
        model="$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2- | xargs)"
    fi

    printf "%s" "$model"

}

cpu_get_architecture() {

    uname -m

}

cpu_get_count() {

    local count="Desconhecido"

    if command_exists nproc; then
        count="$(nproc)"
    fi

    printf "%s" "$count"

}

cpu_get_cores() {

    local cores="Desconhecido"

    if file_exists "/proc/cpuinfo"; then
        cores="$(grep -c '^processor' /proc/cpuinfo)"
    fi

    printf "%s" "$cores"

}

cpu_get_load_average() {

    local load="Desconhecido"

    if file_exists "/proc/loadavg"; then
        load="$(cut -d' ' -f1-3 /proc/loadavg)"
    fi

    printf "%s" "$load"

}

#
# Esta função será utilizada futuramente pelo Core.
# Por enquanto apenas disponibiliza a informação.
#

cpu_get_temperature() {

    if command_exists sensors; then

        sensors 2>/dev/null | \
        awk '
            /\+.*°C/ {
                gsub(/\+/, "", $2)
                gsub(/°C/, "", $2)
                print $2
                exit
            }
        '

    fi

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

cpu_model() {

    printf "Modelo...............: %s\n" \
        "$(cpu_get_model)"

}

cpu_architecture() {

    printf "Arquitetura..........: %s\n" \
        "$(cpu_get_architecture)"

}

cpu_count() {

    printf "CPUs.................: %s\n" \
        "$(cpu_get_count)"

}

cpu_cores() {

    printf "Núcleos..............: %s\n" \
        "$(cpu_get_cores)"

}

cpu_load_average() {

    printf "Load Average.........: %s\n" \
        "$(cpu_get_load_average)"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

cpu_run() {

    info "Coletando informações do processador..."

    echo

    cpu_model
    cpu_architecture
    cpu_count
    cpu_cores
    cpu_load_average

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
