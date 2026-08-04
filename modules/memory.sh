#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Memory Module
#
# Responsável por coletar informações de memória RAM e Swap.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_MEMORY_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_MEMORY_LOADED=1

#===============================================================================
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

memory_get_total() {

    if file_exists "/proc/meminfo"; then
        awk '/MemTotal:/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo
    else
        printf "Desconhecido"
    fi

}

memory_get_available() {

    if file_exists "/proc/meminfo"; then
        awk '/MemAvailable:/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo
    else
        printf "Desconhecido"
    fi

}

memory_get_used() {

    if file_exists "/proc/meminfo"; then

        local total available used

        total="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
        available="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"

        used=$((total - available))

        awk "BEGIN {printf \"%.2f GB\", $used/1024/1024}"

    else

        printf "Desconhecido"

    fi

}

memory_get_usage_percent() {

    if file_exists "/proc/meminfo"; then

        local total available

        total="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
        available="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"

        awk -v t="$total" -v a="$available" \
            'BEGIN {printf "%.1f", ((t-a)/t)*100}'

    else

        printf "Desconhecido"

    fi

}

memory_get_swap_total() {

    if file_exists "/proc/meminfo"; then
        awk '/SwapTotal:/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo
    else
        printf "Desconhecido"
    fi

}

memory_get_swap_free() {

    if file_exists "/proc/meminfo"; then
        awk '/SwapFree:/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo
    else
        printf "Desconhecido"
    fi

}

memory_get_swap_used() {

    if file_exists "/proc/meminfo"; then

        local total free

        total="$(awk '/SwapTotal:/ {print $2}' /proc/meminfo)"
        free="$(awk '/SwapFree:/ {print $2}' /proc/meminfo)"

        awk -v t="$total" -v f="$free" \
            'BEGIN {printf "%.2f GB", (t-f)/1024/1024}'

    else

        printf "Desconhecido"

    fi

}

#===============================================================================
# API EXPANDIDA (PR-004)
#===============================================================================

memory_get_cached() {

    if file_exists "/proc/meminfo"; then

        awk '/^Cached:/ {printf "%.2f GB", $2/1024/1024}' \
            /proc/meminfo

    else

        printf "Desconhecido"

    fi

}

memory_get_buffers() {

    if file_exists "/proc/meminfo"; then

        awk '/^Buffers:/ {printf "%.2f GB", $2/1024/1024}' \
            /proc/meminfo

    else

        printf "Desconhecido"

    fi

}

memory_get_shared() {

    if file_exists "/proc/meminfo"; then

        awk '/^Shmem:/ {printf "%.2f GB", $2/1024/1024}' \
            /proc/meminfo

    else

        printf "Desconhecido"

    fi

}

memory_get_swap_usage_percent() {

    if file_exists "/proc/meminfo"; then

        local total free

        total="$(awk '/SwapTotal:/ {print $2}' /proc/meminfo)"
        free="$(awk '/SwapFree:/ {print $2}' /proc/meminfo)"

        if [[ "$total" -eq 0 ]]; then

            printf "0.0"

        else

            awk -v t="$total" -v f="$free" \
                'BEGIN {printf "%.1f", ((t-f)/t)*100}'

        fi

    else

        printf "Desconhecido"

    fi

}

memory_has_swap() {

    if file_exists "/proc/meminfo"; then

        awk '/SwapTotal:/ {exit ($2 > 0 ? 0 : 1)}' \
            /proc/meminfo

    else

        return 1

    fi

}

memory_get_commit_limit() {

    if file_exists "/proc/meminfo"; then

        awk '/CommitLimit:/ {printf "%.2f GB", $2/1024/1024}' \
            /proc/meminfo

    else

        printf "Desconhecido"

    fi

}

memory_get_committed() {

    if file_exists "/proc/meminfo"; then

        awk '/Committed_AS:/ {printf "%.2f GB", $2/1024/1024}' \
            /proc/meminfo

    else

        printf "Desconhecido"

    fi

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

memory_total() {

    printf "Memória Total........: %s\n" \
        "$(memory_get_total)"

}

memory_available() {

    printf "Memória Disponível...: %s\n" \
        "$(memory_get_available)"

}

memory_used() {

    printf "Memória Utilizada....: %s\n" \
        "$(memory_get_used)"

}

memory_usage_percent() {

    printf "Uso da Memória.......: %s%%\n" \
        "$(memory_get_usage_percent)"

}

memory_swap() {

    printf "Swap Total...........: %s\n" \
        "$(memory_get_swap_total)"

    printf "Swap Utilizada.......: %s\n" \
        "$(memory_get_swap_used)"

    printf "Swap Livre...........: %s\n" \
        "$(memory_get_swap_free)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

memory_run() {

    info "Coletando informações de memória..."

    echo

    memory_total
    memory_available
    memory_used
    memory_usage_percent
    memory_swap

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
