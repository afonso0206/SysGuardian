#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Printers Module
#
# Responsável por coletar informações de impressoras via SNMP.
#===============================================================================

set -euo pipefail

if [[ -n "${SYSGUARDIAN_PRINTERS_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_PRINTERS_LOADED=1

PRINTER_COUNT=0
PRINTER_ONLINE_COUNT=0
PRINTER_OFFLINE_COUNT=0

PRINTER_IPS=()
PRINTER_NAMES=()
PRINTER_STATUSES=()
PRINTER_RESPONSE_TIMES=()
PRINTER_MODELS=()
PRINTER_SERIALS=()
PRINTER_FIRMWARES=()
PRINTER_MACS=()
PRINTER_LOCATIONS=()
PRINTER_DESCRIPTIONS=()
PRINTER_UPTIMES=()
PRINTER_TOTAL_PAGES=()
PRINTER_TONER_BLACK=()
PRINTER_TONER_CYAN=()
PRINTER_TONER_MAGENTA=()
PRINTER_TONER_YELLOW=()
PRINTER_DRUM=()
PRINTER_PAPER_PCT=()
PRINTER_ERRORS=()

#===============================================================================
# CAMADA 1 - API DE COLETA
#===============================================================================

collect_printers() {

local conf_file="${CONFIG_DIR:-/etc/sysguardian}/printers.conf"

[ ! -f "$conf_file" ] && return 0

local cfg_community cfg_version cfg_timeout cfg_retries cfg_port
cfg_community=$(grep -E '^COMMUNITY=' "$conf_file" | cut -d'=' -f2 | xargs || echo "public")
cfg_version=$(grep -E '^VERSION=' "$conf_file" | cut -d'=' -f2 | xargs || echo "2c")
cfg_timeout=$(grep -E '^TIMEOUT=' "$conf_file" | cut -d'=' -f2 | xargs || echo "2")
cfg_retries=$(grep -E '^RETRIES=' "$conf_file" | cut -d'=' -f2 | xargs || echo "1")
cfg_port=$(grep -E '^PORT=' "$conf_file" | cut -d'=' -f2 | xargs || echo "161")

local printer_entries
printer_entries=$(grep -E '^[A-Za-z0-9_]+=' "$conf_file" | grep -vE '^(COMMUNITY|VERSION|TIMEOUT|RETRIES|PORT|DISCOVERY|LOG_LEVEL)=' || true)

[ -z "$printer_entries" ] && return 0

while IFS= read -r line; do
    [ -z "$line" ] && continue
    local alias_name ip_addr
    alias_name=$(echo "$line" | cut -d'=' -f1 | xargs)
    ip_addr=$(echo "$line" | cut -d'=' -f2 | xargs)

    ((PRINTER_COUNT += 1))
    PRINTER_IPS+=("$ip_addr")
    PRINTER_NAMES+=("$alias_name")

    local t_start t_end lat_ms
    t_start=$(date +%s%3N 2>/dev/null || echo "0")

    local walk_out
    walk_out=$(snmpbulkwalk -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" "${ip_addr}:${cfg_port}" .1.3.6.1 2>/dev/null || true)

    t_end=$(date +%s%3N 2>/dev/null || echo "0")
    if [ "$t_start" -gt 0 ] && [ "$t_end" -gt 0 ]; then
        lat_ms=$((t_end - t_start))
    else
        lat_ms=0
    fi
    PRINTER_RESPONSE_TIMES+=("$lat_ms")

    if [ -z "$walk_out" ]; then
        ((PRINTER_OFFLINE_COUNT += 1))
        PRINTER_STATUSES+=("offline")
        PRINTER_MODELS+=("N/A")
        PRINTER_SERIALS+=("N/A")
        PRINTER_FIRMWARES+=("N/A")
        PRINTER_MACS+=("N/A")
        PRINTER_LOCATIONS+=("N/A")
        PRINTER_DESCRIPTIONS+=("N/A")
        PRINTER_UPTIMES+=("0")
        PRINTER_TOTAL_PAGES+=("0")
        PRINTER_TONER_BLACK+=("-1")
        PRINTER_TONER_CYAN+=("-1")
        PRINTER_TONER_MAGENTA+=("-1")
        PRINTER_TONER_YELLOW+=("-1")
        PRINTER_DRUM+=("-1")
        PRINTER_PAPER_PCT+=("-1")
        PRINTER_ERRORS+=("Sem resposta SNMP")
        continue
    fi

    ((PRINTER_ONLINE_COUNT += 1))
    PRINTER_STATUSES+=("online")

    local model serial firmware mac loc descr uptime pages bk_pct=-1 paper_pct=100 err_msg="None"

    model=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.1.1.0 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || echo "HP LaserJet")
    serial=$(echo "$walk_out" | grep "\.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.3.0 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || echo "N/A")
    firmware=$(echo "$walk_out" | grep "\.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.2.0 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || echo "N/A")
    mac=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.2.2.1.6.1 =" | awk -F'= Hex-STRING: ' '{print $2}' | xargs || echo "N/A")
    loc=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.1.6.0 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || echo "N/A")
    descr=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.1.1.0 =" | head -n1 | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || echo "N/A")
    uptime=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.1.3.0 =" | awk -F') ' '{print $2}' | xargs || echo "0")
    pages=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.43.10.2.1.4.1.1 =" | awk -F'= INTEGER: ' '{print $2}' | xargs || echo "0")

    local bk_max bk_cur
    bk_max=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.43.11.1.1.8.1.1 =" | awk -F'= INTEGER: ' '{print $2}' || echo "0")
    bk_cur=$(echo "$walk_out" | grep "\.1.3.6.1.2.1.43.11.1.1.9.1.1 =" | awk -F'= INTEGER: ' '{print $2}' || echo "0")
    if [ "${bk_max:-0}" -gt 0 ] && [ "${bk_cur:-0}" -ge 0 ]; then
        bk_pct=$(( (bk_cur * 100) / bk_max ))
    fi

    PRINTER_MODELS+=("$model")
    PRINTER_SERIALS+=("$serial")
    PRINTER_FIRMWARES+=("$firmware")
    PRINTER_MACS+=("$mac")
    PRINTER_LOCATIONS+=("$loc")
    PRINTER_DESCRIPTIONS+=("$descr")
    PRINTER_UPTIMES+=("$uptime")
    PRINTER_TOTAL_PAGES+=("${pages:-0}")
    PRINTER_TONER_BLACK+=("$bk_pct")
    PRINTER_TONER_CYAN+=("-1")
    PRINTER_TONER_MAGENTA+=("-1")
    PRINTER_TONER_YELLOW+=("-1")
    PRINTER_DRUM+=("-1")
    PRINTER_PAPER_PCT+=("$paper_pct")
    PRINTER_ERRORS+=("$err_msg")

done <<< "$printer_entries"

}

#===============================================================================
# PROTEÇÃO CONTRA EXECUÇÃO DIRETA
#===============================================================================

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    printf "Este módulo faz parte do SysGuardian.\n"
    printf "Execute o programa principal em vez deste arquivo.\n"
    exit 1
fi
