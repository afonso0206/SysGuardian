#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Network Module
#
# Responsável por coletar informações da rede.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_NETWORK_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_NETWORK_LOADED=1

#===============================================================================
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

network_get_default_interface() {

    if command_exists ip; then
        ip route 2>/dev/null | awk '/default/ {print $5; exit}'
    fi

}

network_get_hostname() {

    hostname

}

network_get_fqdn() {

    if command_exists hostname; then
        hostname -f 2>/dev/null || printf "Desconhecido"
    else
        printf "Desconhecido"
    fi

}

network_get_interface() {

    local iface

    iface="$(network_get_default_interface)"

    printf "%s" "${iface:-Desconhecida}"

}

network_get_ipv4() {

    if command_exists ip; then

        ip -4 addr show scope global |
        awk '
            /inet / {
                split($2,a,"/")
                print a[1]
                exit
            }
        '

    else

        printf "Desconhecido"

    fi

}

network_get_ipv6() {

    if command_exists ip; then

        ip -6 addr show scope global |
        awk '/inet6 / {print $2; exit}'

    else

        printf "Não disponível"

    fi

}

network_get_gateway() {

    if command_exists ip; then

        ip route |
        awk '/default/ {print $3; exit}'

    else

        printf "Desconhecido"

    fi

}

network_get_dns() {

    if file_exists "/etc/resolv.conf"; then

        awk '/^nameserver/ {print $2}' /etc/resolv.conf |
        paste -sd ", " -

    else

        printf "Desconhecido"

    fi

}

network_get_mac() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/address"; then

        cat "/sys/class/net/${iface}/address"

    else

        printf "Desconhecido"

    fi

}

network_get_state() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/operstate"; then

        cat "/sys/class/net/${iface}/operstate"

    else

        printf "Desconhecido"

    fi

}

#===============================================================================
# API EXPANDIDA (PR-004)
#===============================================================================

network_get_interfaces() {

    if command_exists ip; then

        ip -o link show |
        awk -F': ' '{print $2}' |
        cut -d'@' -f1

    fi

}

network_get_speed() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/speed"; then

        cat "/sys/class/net/${iface}/speed" 2>/dev/null || true

    else

        printf "N/A"

    fi

}

network_get_rx_errors() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/statistics/rx_errors"; then

        cat "/sys/class/net/${iface}/statistics/rx_errors"

    else

        printf "0"

    fi

}

network_get_tx_errors() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/statistics/tx_errors"; then

        cat "/sys/class/net/${iface}/statistics/tx_errors"

    else

        printf "0"

    fi

}

network_get_rx_drops() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/statistics/rx_dropped"; then

        cat "/sys/class/net/${iface}/statistics/rx_dropped"

    else

        printf "0"

    fi

}

network_get_tx_drops() {

    local iface

    iface="$(network_get_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/statistics/tx_dropped"; then

        cat "/sys/class/net/${iface}/statistics/tx_dropped"

    else

        printf "0"

    fi

}

network_ping_gateway() {

    local gateway

    gateway="$(network_get_gateway)"

    if [[ -n "$gateway" ]] &&
       command_exists ping; then

        ping -c1 -W2 "$gateway" >/dev/null 2>&1

    else

        return 1

    fi

}

network_ping_internet() {

    if command_exists ping; then

        ping -c1 -W3 8.8.8.8 >/dev/null 2>&1

    else

        return 1

    fi

}

network_check_dns() {
    if command_exists getent; then

        getent hosts google.com >/dev/null 2>&1

    elif command_exists host; then

        host google.com >/dev/null 2>&1

    elif command_exists nslookup; then

        nslookup google.com >/dev/null 2>&1

    else

        return 1

    fi

}


#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

network_hostname() {

    printf "Hostname.............: %s\n" \
        "$(network_get_hostname)"

}

network_fqdn() {

    printf "FQDN.................: %s\n" \
        "$(network_get_fqdn)"

}

network_interface() {

    printf "Interface............: %s\n" \
        "$(network_get_interface)"

}

network_ipv4() {

    printf "IPv4.................: %s\n" \
        "$(network_get_ipv4)"

}

network_ipv6() {

    printf "IPv6.................: %s\n" \
        "$(network_get_ipv6)"

}

network_gateway() {

    printf "Gateway..............: %s\n" \
        "$(network_get_gateway)"

}

network_dns() {

    printf "DNS..................: %s\n" \
        "$(network_get_dns)"

}

network_mac() {

    printf "MAC Address..........: %s\n" \
        "$(network_get_mac)"

}

network_state() {

    printf "Estado...............: %s\n" \
        "$(network_get_state)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

network_run() {

    info "Coletando informações de rede..."

    echo

    network_hostname
    network_fqdn
    network_interface
    network_ipv4
    network_ipv6
    network_gateway
    network_dns
    network_mac
    network_state

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