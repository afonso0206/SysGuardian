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
# INTERFACE PADRÃO
#===============================================================================

network_default_interface() {

    if command_exists ip; then
        ip route 2>/dev/null | awk '/default/ {print $5; exit}'
    fi

}

#===============================================================================
# HOSTNAME
#===============================================================================

network_hostname() {

    printf "Hostname.............: %s\n" "$(hostname)"

}

#===============================================================================
# FQDN
#===============================================================================

network_fqdn() {

    local fqdn="Desconhecido"

    if command_exists hostname; then
        fqdn="$(hostname -f 2>/dev/null || echo "Desconhecido")"
    fi

    printf "FQDN.................: %s\n" "$fqdn"

}

#===============================================================================
# INTERFACE PRINCIPAL
#===============================================================================

network_interface() {

    local iface

    iface="$(network_default_interface)"

    printf "Interface............: %s\n" \
        "${iface:-Desconhecida}"

}

#===============================================================================
# IPv4
#===============================================================================

network_ipv4() {

    local ipv4="Desconhecido"

    if command_exists ip; then

        ipv4="$(
            ip -4 addr show scope global |
            awk '
                /inet / {
                    split($2,a,"/")
                    print a[1]
                    exit
                }
            '
        )"

    fi

    printf "IPv4.................: %s\n" \
        "${ipv4:-Desconhecido}"

}

#===============================================================================
# IPv6
#===============================================================================

network_ipv6() {

    local ipv6="Não disponível"

    if command_exists ip; then

        ipv6="$(
            ip -6 addr show scope global |
            awk '/inet6 / {print $2; exit}'
        )"

    fi

    printf "IPv6.................: %s\n" \
        "${ipv6:-Não disponível}"

}

#===============================================================================
# GATEWAY PADRÃO
#===============================================================================

network_gateway() {

    local gateway="Desconhecido"

    if command_exists ip; then

        gateway="$(
            ip route |
            awk '/default/ {print $3; exit}'
        )"

    fi

    printf "Gateway..............: %s\n" \
        "${gateway:-Desconhecido}"

}

#===============================================================================
# DNS
#===============================================================================

network_dns() {

    local dns="Desconhecido"

    if file_exists "/etc/resolv.conf"; then

        dns="$(
            awk '/^nameserver/ {print $2}' /etc/resolv.conf |
            paste -sd ", " -
        )"

    fi

    printf "DNS..................: %s\n" \
        "${dns:-Desconhecido}"

}

#===============================================================================
# MAC ADDRESS
#===============================================================================

network_mac() {

    local iface
    local mac="Desconhecido"

    iface="$(network_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/address"; then

        mac="$(<"/sys/class/net/${iface}/address")"

    fi

    printf "MAC Address..........: %s\n" "$mac"

}

#===============================================================================
# STATUS DA INTERFACE
#===============================================================================

network_state() {

    local iface
    local state="Desconhecido"

    iface="$(network_default_interface)"

    if [[ -n "$iface" ]] &&
       file_exists "/sys/class/net/${iface}/operstate"; then

        state="$(<"/sys/class/net/${iface}/operstate")"

    fi

    printf "Estado...............: %s\n" "$state"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#

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
