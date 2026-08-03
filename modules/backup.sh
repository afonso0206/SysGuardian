#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Backup Module
#
# Responsável por coletar informações sobre backups do sistema.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_BACKUP_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_BACKUP_LOADED=1

#===============================================================================
# DIRETÓRIO PADRÃO DE BACKUP
#===============================================================================

backup_default_directory() {

    if directory_exists "/backup"; then
        printf "/backup"
        return
    fi

    df 2>/dev/null |
        awk '$6 != "/" && $1 ~ /^\/dev\// {print $6; exit}'

}

#===============================================================================
# DIRETÓRIO DE BACKUP
#===============================================================================

backup_directory() {

    local backup_dir

    backup_dir="$(backup_default_directory)"

    printf "Diretório Backup.....: %s\n" \
        "${backup_dir:-Não encontrado}"

}

#===============================================================================
# BACKUPS RECENTES
#===============================================================================

backup_recent() {

    local backup_dir
    local count="0"

    backup_dir="$(backup_default_directory)"

    if [[ -n "${backup_dir:-}" ]] &&
       directory_exists "$backup_dir" &&
       command_exists find; then

        count="$(
            find "$backup_dir" \
                -type f \
                \( \
                    -name "*.tar" \
                    -o -name "*.tar.gz" \
                    -o -name "*.tgz" \
                    -o -name "*.zip" \
                    -o -name "*.bak" \
                    -o -name "*.sql" \
                    -o -name "*.borg" \
                    -o -name "*.restic" \
                \) \
                -mtime -7 \
                2>/dev/null |
            wc -l
        )"

    fi

    printf "Backups Recentes.....: %s\n" "$count"

}

#===============================================================================
# ROTINAS CRON
#===============================================================================

backup_cron() {

    local jobs="0"

    if command_exists crontab; then

        jobs="$(
            (
                crontab -l 2>/dev/null

                grep -rhE \
                    "backup|rsync|borg|restic" \
                    /etc/cron.daily \
                    /etc/cron.weekly \
                    /etc/cron.monthly \
                    2>/dev/null || true

            ) |
            grep -ciE "backup|rsync|borg|restic"
        )"

    fi

    printf "Rotinas Cron.........: %s\n" "$jobs"

}

#===============================================================================
# TIMERS SYSTEMD
#===============================================================================

backup_timers() {

    local timers="0"

    if command_exists systemctl; then

        timers="$(
            systemctl list-timers --all 2>/dev/null |
            grep -ciE "backup|rsync|borg|restic"
        )"

    fi

    printf "Timers...............: %s\n" "$timers"

}

#===============================================================================
# FERRAMENTAS DE BACKUP
#===============================================================================

backup_tools() {

    local tools=()
    local tool
    local list

    for tool in \
        borg \
        restic \
        duplicati \
        timeshift \
        rdiff-backup
    do

        if command_exists "$tool"; then
            tools+=("$tool")
        fi

    done

    if ((${#tools[@]} == 0)); then

        printf "Ferramentas..........: Nenhuma detectada\n"

    else

        list="$(IFS=', '; printf '%s' "${tools[*]}")"

        printf "Ferramentas..........: %s\n" "$list"

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

backup_run() {

    info "Coletando informações de backup..."

    echo

    backup_directory
    backup_recent
    backup_cron
    backup_timers
    backup_tools

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
