#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Logs Module
#
# Responsável por coletar informações dos logs do sistema (journalctl).
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_LOGS_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_LOGS_LOADED=1

#===============================================================================
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

logs_get_errors() {

    if ! command_exists journalctl; then
        return 0
    fi

    journalctl \
        -p err \
        --since "24 hours ago" \
        --no-pager \
        -o short-iso \
        2>/dev/null

}

logs_get_services() {

    logs_get_errors |
    awk '
    {
        svc=$3

        gsub(/\[.*/, "", svc)
        gsub(/:$/, "", svc)

        if (svc != "" && svc != "kernel")
            print svc
    }'

}

logs_get_disk_usage() {

    local raw=""
    local usage="Não disponível"

    if ! command_exists journalctl; then
        printf "journalctl não disponível"
        return
    fi

    if raw="$(journalctl --disk-usage 2>/dev/null)"; then

        usage="$(
            awk '
            {
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /^[0-9]+(\.[0-9]+)?[KMGT]$/) {
                        print $(i-1), $i
                        exit
                    }
                }
            }' <<< "$raw"
        )"

        [[ -z "$usage" ]] && usage="$raw"

    fi

    printf "%s" "$usage"

}

logs_get_total_errors() {

    logs_get_errors | wc -l

}

logs_get_top_services() {

    logs_get_services |
    sort |
    uniq -c |
    sort -rn |
    head -15

}

#----------------------------------------------------------------------------
# APIs preparadas para integração do Core
#----------------------------------------------------------------------------

logs_get_oom_events() {

    if command_exists journalctl; then

        journalctl \
            --since "24 hours ago" \
            --no-pager \
            2>/dev/null |
        grep -Ei "Out of memory|Killed process" || true

    fi

}

logs_get_kernel_errors() {

    if command_exists journalctl; then

        journalctl \
            -k \
            -p err \
            --since "24 hours ago" \
            --no-pager \
            2>/dev/null

    fi

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

logs_disk_usage() {

    printf "Espaço Logs..........: %s\n" \
        "$(logs_get_disk_usage)"

}

logs_total_errors() {

    printf "Entradas de Erro.....: %s\n" \
        "$(logs_get_total_errors)"

}

logs_top_services() {

    local services

    services="$(logs_get_top_services)"

    printf "\n"
    printf "Top Serviços com Erros (24h)\n"
    printf "----------------------------\n"

    if [[ -z "$services" ]]; then

        printf "Nenhum erro encontrado nas últimas 24 horas.\n"

        return

    fi

    awk '{printf "%5s  %s\n",$1,$2}' <<< "$services"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

logs_run() {

    info "Coletando informações dos logs..."

    printf "\n"

    logs_disk_usage
    logs_total_errors
    logs_top_services

    printf "\n"

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
