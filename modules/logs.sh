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
# OBTÉM OS ERROS DO JOURNAL (ÚLTIMAS 24 HORAS)
#===============================================================================

logs_errors() {

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

#===============================================================================
# EXTRAI OS SERVIÇOS COM ERROS
#===============================================================================

logs_services() {

    logs_errors |
    awk '
    {
        svc=$3

        gsub(/\[.*/, "", svc)
        gsub(/:$/, "", svc)

        if (svc != "" && svc != "kernel")
            print svc
    }'

}

#===============================================================================
# ESPAÇO UTILIZADO PELO JOURNAL
#===============================================================================

logs_disk_usage() {

    local raw=""
    local usage="Não disponível"

    if ! command_exists journalctl; then
        printf "Espaço Logs..........: journalctl não disponível\n"
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

    printf "Espaço Logs..........: %s\n" "$usage"

}

#===============================================================================
# TOTAL DE ERROS
#===============================================================================

logs_total_errors() {

    local total

    total="$(logs_errors | wc -l)"

    printf "Entradas de Erro.....: %s\n" "$total"

}

#===============================================================================
# TOP SERVIÇOS COM ERROS
#===============================================================================

logs_top_services() {

    local services

    services="$(
        logs_services |
        sort |
        uniq -c |
        sort -rn |
        head -15
    )"

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
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

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
