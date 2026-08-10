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
    walk_out=$(snmpget -On -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" \
        "${ip_addr}:${cfg_port}" \
        .1.3.6.1.2.1.1.1.0 \
        .1.3.6.1.2.1.25.3.2.1.3.1 \
        .1.3.6.1.2.1.43.5.1.1.17.1 \
        .1.3.6.1.2.1.1.6.0 \
        .1.3.6.1.2.1.1.3.0 2>/dev/null || true)

    walk_out=$(printf '%s\n' "$walk_out" | \
        grep -vE ' = (No Such Object|No Such Instance)' | \
        grep -vE '= (STRING: )?""$' || true)

    local interface_out
    interface_out=$(snmpwalk -On -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" \
        "${ip_addr}:${cfg_port}" .1.3.6.1.2.1.2.2.1 2>/dev/null || true)
    interface_out=$(printf '%s\n' "$interface_out" | \
        grep -vE ' = (No Such Object|No Such Instance)' || true)

    local marker_out input_out supplies_out colorants_out
    marker_out=$(snmpwalk -On -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" \
        "${ip_addr}:${cfg_port}" .1.3.6.1.2.1.43.10.2.1 2>/dev/null || true)
    input_out=$(snmpwalk -On -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" \
        "${ip_addr}:${cfg_port}" .1.3.6.1.2.1.43.8.2.1 2>/dev/null || true)
    supplies_out=$(snmpwalk -On -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" \
        "${ip_addr}:${cfg_port}" .1.3.6.1.2.1.43.11.1.1 2>/dev/null || true)
    colorants_out=$(snmpwalk -On -Oa -v "$cfg_version" -c "$cfg_community" -t "$cfg_timeout" -r "$cfg_retries" \
        "${ip_addr}:${cfg_port}" .1.3.6.1.2.1.43.12 2>/dev/null || true)

    marker_out=$(printf '%s\n' "$marker_out" | grep -vE ' = (No Such Object|No Such Instance)' || true)
    input_out=$(printf '%s\n' "$input_out" | grep -vE ' = (No Such Object|No Such Instance)' || true)
    supplies_out=$(printf '%s\n' "$supplies_out" | grep -vE ' = (No Such Object|No Such Instance)' || true)
    colorants_out=$(printf '%s\n' "$colorants_out" | grep -vE ' = (No Such Object|No Such Instance)' || true)

    t_end=$(date +%s%3N 2>/dev/null || echo "0")
    if [ "$t_start" -gt 0 ] && [ "$t_end" -gt 0 ]; then
        lat_ms=$((t_end - t_start))
    else
        lat_ms=0
    fi
    PRINTER_RESPONSE_TIMES+=("$lat_ms")

    if [ -z "$walk_out" ] && [ -z "$interface_out" ]; then
        ((PRINTER_OFFLINE_COUNT += 1))
        PRINTER_STATUSES+=("offline")
        PRINTER_MODELS+=("N/A")
        PRINTER_SERIALS+=("N/A")
        PRINTER_FIRMWARES+=("N/A")
        PRINTER_MACS+=("N/A")
        PRINTER_LOCATIONS+=("N/A")
        PRINTER_DESCRIPTIONS+=("N/A")
        PRINTER_UPTIMES+=("0")
        PRINTER_TOTAL_PAGES+=("N/A")
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

    local model serial firmware="N/A" mac="N/A" loc descr uptime pages="N/A"
    local toner_black=-1 toner_cyan=-1 toner_magenta=-1 toner_yellow=-1
    local paper_pct=-1 drum_pct=-1 err_msg="None"

    model=$(printf '%s\n' "$walk_out" | grep "\.1.3.6.1.2.1.25.3.2.1.3.1 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || true)
    serial=$(printf '%s\n' "$walk_out" | grep "\.1.3.6.1.2.1.43.5.1.1.17.1 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || true)
    loc=$(printf '%s\n' "$walk_out" | grep "\.1.3.6.1.2.1.1.6.0 =" | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || true)
    descr=$(printf '%s\n' "$walk_out" | grep "\.1.3.6.1.2.1.1.1.0 =" | head -n1 | awk -F'= STRING: ' '{print $2}' | tr -d '"' | xargs || true)
    uptime=$(printf '%s\n' "$walk_out" | grep "\.1.3.6.1.2.1.1.3.0 =" | awk -F') ' '{print $2}' | xargs || true)

    model="${model:-N/A}"
    serial="${serial:-N/A}"
    loc="${loc:-N/A}"
    descr="${descr:-N/A}"
    uptime="${uptime:-N/A}"

    local interface_index interface_mac fallback_mac=""
    while IFS= read -r interface_index; do
        interface_mac=$(printf '%s\n' "$interface_out" | \
            grep -F ".1.3.6.1.2.1.2.2.1.6.${interface_index} =" | \
            awk -F'= Hex-STRING: ' '{print $2}' | xargs || true)

        [ -z "$interface_mac" ] && continue
        [ -z "$fallback_mac" ] && fallback_mac="$interface_mac"

        if printf '%s\n' "$interface_out" | \
           grep -Fq ".1.3.6.1.2.1.2.2.1.8.${interface_index} = INTEGER: 1"; then
            mac="$interface_mac"
            break
        fi
    done < <(printf '%s\n' "$interface_out" | \
        sed -n 's/^\.1\.3\.6\.1\.2\.1\.2\.2\.1\.3\.\([0-9][0-9]*\) = INTEGER: 6$/\1/p')

    [ "$mac" == "N/A" ] && mac="${fallback_mac:-N/A}"

    if [[ "$descr" =~ ^([^;]+)\;[[:space:]]*(V[[:alnum:]._-]+)([[:space:]]|\;|$) ]]; then
        firmware="${BASH_REMATCH[2]}"
    fi

    local marker_index marker_value marker_candidates=0
    while IFS= read -r marker_index; do
        marker_value=$(printf '%s\n' "$marker_out" | \
            grep -E "^\\.1\\.3\\.6\\.1\\.2\\.1\\.43\\.10\\.2\\.1\\.4\\.${marker_index} = (Counter32|INTEGER): [0-9]+$" | \
            awk -F': ' '{print $2}' | xargs || true)

        if [[ "$marker_value" =~ ^[0-9]+$ ]]; then
            marker_candidates=$((marker_candidates + 1))
            pages="$marker_value"
        fi
    done < <(printf '%s\n' "$marker_out" | \
        sed -n 's/^\.1\.3\.6\.1\.2\.1\.43\.10\.2\.1\.3\.\([0-9][0-9.]*\) = INTEGER: 7$/\1/p')

    [ "$marker_candidates" -eq 1 ] || pages="N/A"

    local input_index input_unit input_max input_level
    local input_count=0 all_inputs_measurable=1 total_capacity=0 total_level=0
    while read -r input_index input_unit; do
        input_count=$((input_count + 1))
        input_max=$(printf '%s\n' "$input_out" | \
            grep -F ".1.3.6.1.2.1.43.8.2.1.9.${input_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        input_level=$(printf '%s\n' "$input_out" | \
            grep -F ".1.3.6.1.2.1.43.8.2.1.10.${input_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)

        if [[ "$input_unit" != "8" || ! "$input_max" =~ ^[1-9][0-9]*$ || ! "$input_level" =~ ^[0-9]+$ ]]; then
            all_inputs_measurable=0
            continue
        fi

        total_capacity=$((total_capacity + input_max))
        total_level=$((total_level + input_level))
    done < <(printf '%s\n' "$input_out" | \
        sed -n 's/^\.1\.3\.6\.1\.2\.1\.43\.8\.2\.1\.8\.\([0-9][0-9.]*\) = INTEGER: \(-\{0,1\}[0-9][0-9]*\)$/\1 \2/p')

    if [ "$input_count" -gt 0 ] && [ "$all_inputs_measurable" -eq 1 ] && [ "$total_capacity" -gt 0 ]; then
        paper_pct=$((total_level * 100 / total_capacity))
    fi

    local supply_index supply_unit supply_max supply_level supply_pct
    local drum_candidates=0
    while IFS= read -r supply_index; do
        supply_unit=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.7.${supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        supply_max=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.8.${supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        supply_level=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.9.${supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        supply_pct=""

        if [[ "$supply_unit" == "19" && "$supply_level" =~ ^[0-9]+$ && "$supply_level" -le 100 ]]; then
            supply_pct="$supply_level"
        elif [[ "$supply_unit" == "7" && "$supply_max" =~ ^[1-9][0-9]*$ && "$supply_level" =~ ^[0-9]+$ ]]; then
            supply_pct=$((supply_level * 100 / supply_max))
        fi

        if [[ "$supply_pct" =~ ^[0-9]+$ ]]; then
            drum_candidates=$((drum_candidates + 1))
            drum_pct="$supply_pct"
        fi
    done < <(printf '%s\n' "$supplies_out" | \
        sed -n 's/^\.1\.3\.6\.1\.2\.1\.43\.11\.1\.1\.5\.\([0-9][0-9.]*\) = INTEGER: 9$/\1/p')

    [ "$drum_candidates" -eq 1 ] || drum_pct=-1

    local toner_supply_index toner_marker_index toner_colorant_index toner_color
    local toner_unit toner_max toner_level toner_pct
    local black_candidates=0 cyan_candidates=0 magenta_candidates=0 yellow_candidates=0
    while IFS= read -r toner_supply_index; do
        toner_marker_index="${toner_supply_index%%.*}"
        toner_colorant_index=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.3.${toner_supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        [[ "$toner_colorant_index" =~ ^[0-9]+$ ]] || continue

        toner_color=$(printf '%s\n' "$colorants_out" | \
            grep -F ".1.3.6.1.2.1.43.12.1.1.4.${toner_marker_index}.${toner_colorant_index} =" | \
            awk -F'= STRING: ' '{print $2}' | tr -d '"' | \
            sed 's/[.[:space:]]*$//' | tr '[:upper:]' '[:lower:]' | xargs || true)
        [[ "$toner_color" =~ ^(black|cyan|magenta|yellow)$ ]] || continue

        toner_unit=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.7.${toner_supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        toner_max=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.8.${toner_supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        toner_level=$(printf '%s\n' "$supplies_out" | \
            grep -F ".1.3.6.1.2.1.43.11.1.1.9.${toner_supply_index} =" | \
            awk -F': ' '{print $2}' | xargs || true)
        toner_pct=""

        if [[ "$toner_unit" == "19" && "$toner_level" =~ ^[0-9]+$ && "$toner_level" -le 100 ]]; then
            toner_pct="$toner_level"
        elif [[ "$toner_max" =~ ^[1-9][0-9]*$ && "$toner_level" =~ ^[0-9]+$ ]]; then
            toner_pct=$((toner_level * 100 / toner_max))
        fi

        [[ "$toner_pct" =~ ^[0-9]+$ && "$toner_pct" -le 100 ]] || continue

        case "$toner_color" in
            black)
                black_candidates=$((black_candidates + 1))
                toner_black="$toner_pct"
                ;;
            cyan)
                cyan_candidates=$((cyan_candidates + 1))
                toner_cyan="$toner_pct"
                ;;
            magenta)
                magenta_candidates=$((magenta_candidates + 1))
                toner_magenta="$toner_pct"
                ;;
            yellow)
                yellow_candidates=$((yellow_candidates + 1))
                toner_yellow="$toner_pct"
                ;;
        esac
    done < <(printf '%s\n' "$supplies_out" | \
        sed -n 's/^\.1\.3\.6\.1\.2\.1\.43\.11\.1\.1\.5\.\([0-9][0-9.]*\) = INTEGER: \(3\|21\)$/\1/p')

    [ "$black_candidates" -eq 1 ] || toner_black=-1
    [ "$cyan_candidates" -eq 1 ] || toner_cyan=-1
    [ "$magenta_candidates" -eq 1 ] || toner_magenta=-1
    [ "$yellow_candidates" -eq 1 ] || toner_yellow=-1

    PRINTER_MODELS+=("$model")
    PRINTER_SERIALS+=("$serial")
    PRINTER_FIRMWARES+=("$firmware")
    PRINTER_MACS+=("$mac")
    PRINTER_LOCATIONS+=("$loc")
    PRINTER_DESCRIPTIONS+=("$descr")
    PRINTER_UPTIMES+=("$uptime")
    PRINTER_TOTAL_PAGES+=("${pages:-N/A}")
    PRINTER_TONER_BLACK+=("$toner_black")
    PRINTER_TONER_CYAN+=("$toner_cyan")
    PRINTER_TONER_MAGENTA+=("$toner_magenta")
    PRINTER_TONER_YELLOW+=("$toner_yellow")
    PRINTER_DRUM+=("$drum_pct")
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
