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
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

disk_has_df() {

    command_exists df

}

disk_get_total() {

    if disk_has_df; then
        df -h / | awk 'NR==2 {print $2}'
    else
        printf "Desconhecido"
    fi

}

disk_get_used() {

    if disk_has_df; then
        df -h / | awk 'NR==2 {print $3}'
    else
        printf "Desconhecido"
    fi

}

disk_get_available() {

    if disk_has_df; then
        df -h / | awk 'NR==2 {print $4}'
    else
        printf "Desconhecido"
    fi

}

disk_get_usage() {

    if disk_has_df; then
        df -h / | awk 'NR==2 {print $5}'
    else
        printf "Desconhecido"
    fi

}

disk_get_usage_percent() {

    if disk_has_df; then
        df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
    else
        printf "0"
    fi

}

disk_get_filesystem() {

    if disk_has_df; then
        df -T / | awk 'NR==2 {print $2}'
    else
        printf "Desconhecido"
    fi

}

disk_get_mountpoint() {

    printf "/"

}

#===============================================================================
# API EXPANDIDA (PR-004)
#===============================================================================

disk_get_partition_usage() {

    if disk_has_df; then

        df -hT \
            --output=source,fstype,size,used,avail,pcent,target \
            2>/dev/null || true

    fi

}

disk_get_mounts() {

    if command_exists findmnt; then

        findmnt -rn 2>/dev/null || true

    elif file_exists "/proc/mounts"; then

        cat /proc/mounts 2>/dev/null || true

    fi

}

disk_get_inodes() {

    if disk_has_df; then

        df -i 2>/dev/null || true

    fi

}
disk_get_physical_disks() {

    if command_exists lsblk; then

        lsblk \
            -d \
            -e7 \
            -o NAME,SIZE,MODEL,ROTA,TRAN \
            -n \
            2>/dev/null |
        awk '$1 !~ /^(loop|ram|zram|dm-)/'

    fi

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

disk_total() {

    printf "Espaço Total.........: %s\n" \
        "$(disk_get_total)"

}

disk_used() {

    printf "Espaço Utilizado.....: %s\n" \
        "$(disk_get_used)"

}

disk_available() {

    printf "Espaço Livre.........: %s\n" \
        "$(disk_get_available)"

}

disk_usage() {

    printf "Utilização...........: %s\n" \
        "$(disk_get_usage)"

}

disk_filesystem() {

    printf "Sistema de Arquivos..: %s\n" \
        "$(disk_get_filesystem)"

}

disk_mountpoint() {

    printf "Ponto de Montagem....: %s\n" \
        "$(disk_get_mountpoint)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

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
