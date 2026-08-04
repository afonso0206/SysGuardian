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
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

backup_get_default_directory() {

    if directory_exists "/backup"; then
        printf "/backup"
        return
    fi

    df 2>/dev/null |
        awk '$6 != "/" && $1 ~ /^\/dev\// {print $6; exit}'

}

backup_get_directory() {

    local backup_dir

    backup_dir="$(backup_get_default_directory)"

    printf "%s" "${backup_dir:-Não encontrado}"

}

backup_get_recent_count() {

    local backup_dir
    local count="0"

    backup_dir="$(backup_get_default_directory)"

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

    printf "%s" "$count"

}

backup_get_cron_jobs() {

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

    printf "%s" "$jobs"

}

backup_get_timers() {

    local timers="0"

    if command_exists systemctl; then

        timers="$(
            systemctl list-timers --all 2>/dev/null |
            grep -ciE "backup|rsync|borg|restic"
        )"

    fi

    printf "%s" "$timers"

}

backup_get_tools() {

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
        printf "Nenhuma detectada"
    else
        list="$(IFS=', '; printf '%s' "${tools[*]}")"
        printf "%s" "$list"
    fi

}

#----------------------------------------------------------------------------
# APIs preparadas para integração do Core
#----------------------------------------------------------------------------

backup_get_status() {

    if [[ "$(backup_get_recent_count)" -gt 0 ]]; then
        printf "OK"
    else
        printf "Sem backups recentes"
    fi

}

#----------------------------------------------------------------------------
# APIs adicionais para integração do Core (PR-004)
#----------------------------------------------------------------------------

backup_get_last_backup() {

    local backup_dir

    backup_dir="$(backup_get_default_directory)"

    if [[ -n "${backup_dir:-}" ]] &&
       directory_exists "$backup_dir" &&
       command_exists find; then

        find "$backup_dir" \
            -type f \
            -printf '%T@ %p\n' \
            2>/dev/null |
        sort -nr |
        head -1 |
        cut -d' ' -f2-

    fi

}

backup_get_total_backups() {

    local backup_dir

    backup_dir="$(backup_get_default_directory)"

    if [[ -n "${backup_dir:-}" ]] &&
       directory_exists "$backup_dir" &&
       command_exists find; then

        find "$backup_dir" \
            -type f \
            2>/dev/null |
        wc -l

    else

        printf "0"

    fi

}

backup_has_recent_backup() {

    [[ "$(backup_get_recent_count)" -gt 0 ]]

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

backup_directory() {

    printf "Diretório Backup.....: %s\n" \
        "$(backup_get_directory)"

}

backup_recent() {

    printf "Backups Recentes.....: %s\n" \
        "$(backup_get_recent_count)"

}

backup_cron() {

    printf "Rotinas Cron.........: %s\n" \
        "$(backup_get_cron_jobs)"

}

backup_timers() {

    printf "Timers...............: %s\n" \
        "$(backup_get_timers)"

}

backup_tools() {

    printf "Ferramentas..........: %s\n" \
        "$(backup_get_tools)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

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
