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
# CAMADA 1 - API DE COLETA (GETTERS)
#===============================================================================

security_get_firewall() {

    if command_exists ufw; then

        ufw status 2>/dev/null |
        awk 'NR==1 {print; exit}'

    elif command_exists firewall-cmd; then

        printf "Firewalld"

    elif command_exists iptables; then

        printf "iptables"

    else

        printf "Não detectado"

    fi

}

security_get_selinux() {

    if command_exists getenforce; then
        getenforce
    else
        printf "Não instalado"
    fi

}

security_get_apparmor() {

    if file_exists "/sys/module/apparmor/parameters/enabled"; then

        if grep -q '^Y$' /sys/module/apparmor/parameters/enabled; then
            printf "Ativo"
        else
            printf "Inativo"
        fi

    else

        printf "Não instalado"

    fi

}

security_get_secureboot() {

    if command_exists mokutil; then

        if mokutil --sb-state 2>/dev/null |
            grep -qi enabled; then

            printf "Ativado"

        else

            printf "Desativado"

        fi

    else

        printf "Desconhecido"

    fi

}

security_get_root_users() {

    if file_exists "/etc/passwd"; then

        awk -F: '$3==0{c++}END{print c+0}' /etc/passwd

    else

        printf "Desconhecido"

    fi

}

security_get_tcp_ports() {

    if command_exists ss; then

        ss -tln 2>/dev/null |
        awk 'NR>1{c++}END{print c+0}'

    else

        printf "Desconhecido"

    fi

}

security_get_udp_ports() {

    if command_exists ss; then

        ss -uln 2>/dev/null |
        awk 'NR>1{c++}END{print c+0}'

    else

        printf "Desconhecido"

    fi

}

#----------------------------------------------------------------------------
# APIs para futura integração do Core
#----------------------------------------------------------------------------

security_get_failed_logins() {

    if command_exists journalctl; then

        journalctl --since today 2>/dev/null |
        grep -ci "Failed password" || true

    else

        printf "0"

    fi

}

security_get_ssh_root_login() {

    if file_exists "/etc/ssh/sshd_config"; then

        grep -Ei '^[[:space:]]*PermitRootLogin' \
            /etc/ssh/sshd_config 2>/dev/null |
        tail -1 |
        awk '{print $2}'

    fi

}

#----------------------------------------------------------------------------
# APIs adicionais para integração do Core (PR-004)
#----------------------------------------------------------------------------

security_is_ssh_active() {

    local svc

    if command_exists systemctl; then

        for svc in ssh sshd; do

            if systemctl is-active --quiet "$svc" 2>/dev/null; then
                return 0
            fi

        done

        if systemctl is-active --quiet ssh.socket 2>/dev/null; then
            return 0
        fi

    fi

    if command_exists ss; then

        ss -tln 2>/dev/null |
        grep -qE ':22([[:space:]]|$)' &&
        return 0

    fi

    return 1

}

security_is_fail2ban_active() {

    command_exists systemctl &&
    systemctl is-active --quiet fail2ban

}

security_is_auditd_active() {

    command_exists systemctl &&
    systemctl is-active --quiet auditd

}

security_get_pending_updates() {

    if command_exists apt-get; then

        apt-get -s upgrade 2>/dev/null |
        grep -c '^Inst' || true

    else

        printf "0"

    fi

}

security_get_security_updates() {

    if command_exists apt-get; then

        apt-get -s upgrade 2>/dev/null |
        grep -ci 'security' || true

    else

        printf "0"

    fi

}

security_get_kernel_updates() {

    if command_exists apt-get; then

        apt-get -s upgrade 2>/dev/null |
        grep -ciE 'linux-image|linux-headers' || true

    else

        printf "0"

    fi

}

security_get_suid_files() {

    find /usr /etc \
        -perm -4000 \
        -type f \
        2>/dev/null |
    wc -l

}

security_get_world_writable() {

    find /usr /etc \
        -perm -0002 \
        -type f \
        2>/dev/null |
    wc -l

}

security_get_sudo_users() {

    getent group sudo |
    cut -d: -f4

}

#===============================================================================
# CAMADA 2 - APRESENTAÇÃO
#===============================================================================

security_firewall() {

    printf "Firewall.............: %s\n" \
        "$(security_get_firewall)"

}

security_selinux() {

    printf "SELinux..............: %s\n" \
        "$(security_get_selinux)"

}

security_apparmor() {

    printf "AppArmor.............: %s\n" \
        "$(security_get_apparmor)"

}

security_secureboot() {

    printf "Secure Boot..........: %s\n" \
        "$(security_get_secureboot)"

}

security_root_users() {

    printf "Usuários UID 0.......: %s\n" \
        "$(security_get_root_users)"

}

security_tcp_ports() {

    printf "Portas TCP...........: %s\n" \
        "$(security_get_tcp_ports)"

}

security_udp_ports() {

    printf "Portas UDP...........: %s\n" \
        "$(security_get_udp_ports)"

}

#===============================================================================
# CAMADA 3 - EXECUÇÃO
#===============================================================================

#
# Função pública do módulo.
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
