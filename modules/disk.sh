#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Disk Module
#
# Responsável por coletar informações dos sistemas de arquivos.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_DISK_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_DISK_LOADED=1

#===============================================================================
# VERIFICAR DISPONIBILIDADE DO DF
#===============================================================================

disk_has_df() {

    command_exists df

}

#===============================================================================
# ESPAÇO TOTAL
#===============================================================================

disk_total() {

    local total="Desconhecido"

    if disk_has_df; then
        total="$(df -h / | awk 'NR==2 {print $2}')"
    fi

    printf "Espaço Total.........: %s\n" "$total"

}

#===============================================================================
# ESPAÇO UTILIZADO
#===============================================================================

disk_used() {

    local used="Desconhecido"

    if disk_has_df; then
        used="$(df -h / | awk 'NR==2 {print $3}')"
    fi

    printf "Espaço Utilizado.....: %s\n" "$used"

}

#===============================================================================
# ESPAÇO LIVRE
#===============================================================================

disk_available() {

    local available="Desconhecido"

    if disk_has_df; then
        available="$(df -h / | awk 'NR==2 {print $4}')"
    fi

    printf "Espaço Livre.........: %s\n" "$available"

}

#===============================================================================
# UTILIZAÇÃO
#===============================================================================

disk_usage() {

    local usage="Desconhecido"

    if disk_has_df; then
        usage="$(df -h / | awk 'NR==2 {print $5}')"
    fi

    printf "Utilização...........: %s\n" "$usage"

}

#===============================================================================
# SISTEMA DE ARQUIVOS
#===============================================================================

disk_filesystem() {

    local filesystem="Desconhecido"

    if disk_has_df; then
        filesystem="$(df -T / | awk 'NR==2 {print $2}')"
    fi

    printf "Sistema de Arquivos..: %s\n" "$filesystem"

}

#===============================================================================
# PONTO DE MONTAGEM
#===============================================================================

disk_mountpoint() {

    printf "Ponto de Montagem....: /\n"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

disk_run() {

    info "Coletando informações de armazenamento..."

    echo

    disk_filesystem
    disk_mountpoint
    disk_total
    disk_used
    disk_available
    disk_usage

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
