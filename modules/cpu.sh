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
# API EXPANDIDA (PR-004)
#===============================================================================

cpu_get_vendor() {

    if file_exists "/proc/cpuinfo"; then

        awk -F': ' '/vendor_id/ {print $2; exit}' /proc/cpuinfo

    else

        printf "Desconhecido"

    fi

}

cpu_get_frequency() {

    if file_exists "/proc/cpuinfo"; then

        awk -F': ' '/cpu MHz/ {printf "%.0f MHz\n", $2; exit}' \
            /proc/cpuinfo

    else

        printf "Desconhecida"

    fi

}

cpu_get_cache() {

    if file_exists "/proc/cpuinfo"; then

        awk -F': ' '/cache size/ {print $2; exit}' /proc/cpuinfo

    else

        printf "Desconhecido"

    fi

}

cpu_get_flags() {

    if file_exists "/proc/cpuinfo"; then

        awk -F': ' '/flags/ {print $2; exit}' /proc/cpuinfo

    fi

}

cpu_get_governor() {

    if file_exists \
        "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"; then

        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

    else

        printf "Desconhecido"

    fi

}

cpu_get_scaling_driver() {

    if file_exists \
        "/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver"; then

        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver

    else

        printf "Desconhecido"

    fi

}

cpu_get_usage_percent() {

    if command_exists uptime; then

        uptime |
        awk -F'load average:' '{gsub(/^ +/, "", $2); print $2}'

    else

        printf "Desconhecido"

    fi

}

cpu_is_virtualized() {

    if command_exists systemd-detect-virt; then

        systemd-detect-virt --quiet

    elif file_exists "/proc/cpuinfo"; then

        grep -qi hypervisor /proc/cpuinfo

    else

        return 1

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
