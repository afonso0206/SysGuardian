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
# MEMÓRIA TOTAL
#===============================================================================

memory_total() {

    local total="Desconhecido"

    if file_exists "/proc/meminfo"; then
        total="$(awk '/MemTotal:/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)"
    fi

    printf "Memória Total........: %s\n" "$total"

}

#===============================================================================
# MEMÓRIA DISPONÍVEL
#===============================================================================

memory_available() {

    local available="Desconhecido"

    if file_exists "/proc/meminfo"; then
        available="$(awk '/MemAvailable:/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)"
    fi

    printf "Memória Disponível...: %s\n" "$available"

}

#===============================================================================
# MEMÓRIA UTILIZADA
#===============================================================================

memory_used() {

    local total available used

    if file_exists "/proc/meminfo"; then

        total="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
        available="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"

        used=$((total - available))

        printf "Memória Utilizada....: %.2f GB\n" \
            "$(awk "BEGIN {print $used/1024/1024}")"

    else

        printf "Memória Utilizada....: Desconhecido\n"

    fi

}

#===============================================================================
# USO DA MEMÓRIA
#===============================================================================

memory_usage_percent() {

    local total available

    if file_exists "/proc/meminfo"; then

        total="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
        available="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"

        awk -v t="$total" -v a="$available" \
            'BEGIN {
                printf "Uso da Memória......: %.1f%%\n", ((t-a)/t)*100
            }'

    else

        printf "Uso da Memória......: Desconhecido\n"

    fi

}

#===============================================================================
# SWAP
#===============================================================================

memory_swap() {

    local total used free

    if file_exists "/proc/meminfo"; then

        total="$(awk '/SwapTotal:/ {printf "%.2f", $2/1024/1024}' /proc/meminfo)"
        free="$(awk '/SwapFree:/ {printf "%.2f", $2/1024/1024}' /proc/meminfo)"

        used="$(awk -v t="$total" -v f="$free" \
            'BEGIN {printf "%.2f", t-f}')"

        printf "Swap Total...........: %s GB\n" "$total"
        printf "Swap Utilizada.......: %s GB\n" "$used"
        printf "Swap Livre...........: %s GB\n" "$free"

    else

        printf "Swap Total...........: Desconhecido\n"
        printf "Swap Utilizada.......: Desconhecido\n"
        printf "Swap Livre...........: Desconhecido\n"

    fi

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

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
