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
# MODELO DO PROCESSADOR
#===============================================================================

cpu_model() {

    local model="Desconhecido"

    if file_exists "/proc/cpuinfo"; then
        model="$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2- | xargs)"
    fi

    printf "Modelo...............: %s\n" "$model"

}

#===============================================================================
# ARQUITETURA
#===============================================================================

cpu_architecture() {

    printf "Arquitetura..........: %s\n" "$(uname -m)"

}

#===============================================================================
# QUANTIDADE DE PROCESSADORES
#===============================================================================

cpu_count() {

    local count="Desconhecido"

    if command_exists nproc; then
        count="$(nproc)"
    fi

    printf "CPUs.................: %s\n" "$count"

}

#===============================================================================
# NÚCLEOS
#===============================================================================

cpu_cores() {

    local cores="Desconhecido"

    if file_exists "/proc/cpuinfo"; then
        cores="$(grep -c '^processor' /proc/cpuinfo)"
    fi

    printf "Núcleos..............: %s\n" "$cores"

}

#===============================================================================
# LOAD AVERAGE
#===============================================================================

cpu_load_average() {

    local load="Desconhecido"

    if file_exists "/proc/loadavg"; then
        load="$(cut -d' ' -f1-3 /proc/loadavg)"
    fi

    printf "Load Average.........: %s\n" "$load"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

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
