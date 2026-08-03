#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Security Module
#
# Responsável por coletar informações de segurança do sistema.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_SECURITY_LOADED:-}" ]]; then
    return 0
fi

readonly SYSGUARDIAN_SECURITY_LOADED=1

#===============================================================================
# FIREWALL
#===============================================================================

security_firewall() {

    local firewall="Não detectado"

    if command_exists ufw; then

        firewall="$(
            ufw status 2>/dev/null |
            awk 'NR==1 {print; exit}'
        )"

    elif command_exists firewall-cmd; then

        firewall="Firewalld"

    elif command_exists iptables; then

        firewall="iptables"

    fi

    printf "Firewall.............: %s\n" "$firewall"

}

#===============================================================================
# SELINUX
#===============================================================================

security_selinux() {

    local status="Não instalado"

    if command_exists getenforce; then
        status="$(getenforce)"
    fi

    printf "SELinux..............: %s\n" "$status"

}

#===============================================================================
# APPARMOR
#===============================================================================

security_apparmor() {

    local status="Não instalado"

    if file_exists "/sys/module/apparmor/parameters/enabled"; then

        if grep -q '^Y$' /sys/module/apparmor/parameters/enabled; then
            status="Ativo"
        else
            status="Inativo"
        fi

    fi

    printf "AppArmor.............: %s\n" "$status"

}

#===============================================================================
# SECURE BOOT
#===============================================================================

security_secureboot() {

    local status="Desconhecido"

    if command_exists mokutil; then

        if mokutil --sb-state 2>/dev/null |
            grep -qi enabled; then

            status="Ativado"

        else

            status="Desativado"

        fi

    fi

    printf "Secure Boot..........: %s\n" "$status"

}

#===============================================================================
# USUÁRIOS UID 0
#===============================================================================

security_root_users() {

    local count="Desconhecido"

    if file_exists "/etc/passwd"; then

        count="$(
            awk -F: '$3==0{c++}END{print c+0}' /etc/passwd
        )"

    fi

    printf "Usuários UID 0.......: %s\n" "$count"

}

#===============================================================================
# PORTAS TCP
#===============================================================================

security_tcp_ports() {

    local total="Desconhecido"

    if command_exists ss; then

        total="$(
            ss -tln 2>/dev/null |
            awk 'NR>1{c++}END{print c+0}'
        )"

    fi

    printf "Portas TCP...........: %s\n" "$total"

}

#===============================================================================
# PORTAS UDP
#===============================================================================

security_udp_ports() {

    local total="Desconhecido"

    if command_exists ss; then

        total="$(
            ss -uln 2>/dev/null |
            awk 'NR>1{c++}END{print c+0}'
        )"

    fi

    printf "Portas UDP...........: %s\n" "$total"

}

#===============================================================================
# EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
#
# Esta é a única função que deve ser chamada externamente.
#

security_run() {

    info "Coletando informações de segurança..."

    echo

    security_firewall
    security_selinux
    security_apparmor
    security_secureboot
    security_root_users
    security_tcp_ports
    security_udp_ports

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
