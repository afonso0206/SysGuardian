#!/usr/bin/env bash
#===============================================================================
# SysGuardian
# Core Library
#
# Biblioteca principal compartilhada do projeto.
#
# Version : 7.0.0-alpha2
# License : MIT
#===============================================================================

set -euo pipefail

#===============================================================================
# PROTEÇÃO CONTRA CARREGAMENTO MÚLTIPLO
#===============================================================================

if [[ -n "${SYSGUARDIAN_CORE_LOADED:-}" ]]; then
    return 0 2>/dev/null
fi

readonly SYSGUARDIAN_CORE_LOADED=1

#===============================================================================
# INFORMAÇÕES
#===============================================================================

readonly SG_NAME="SysGuardian"
readonly SG_VERSION="7.0.0-alpha2"

#===============================================================================
# CORES
#===============================================================================

# shellcheck disable=SC2034

readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_CYAN='\033[0;36m'
readonly C_BOLD='\033[1m'

#===============================================================================
# MENSAGENS
#===============================================================================

info() {

    printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"

}

ok() {

    printf "${C_GREEN}[ OK ]${C_RESET} %s\n" "$1"

}

warn() {

    printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"

}

error() {

    printf "${C_RED}[ERRO]${C_RESET} %s\n" "$1" >&2

}

die() {

    error "$1"
    exit 1

}

#===============================================================================
# INTERFACE
#===============================================================================

horizontal_rule() {

    printf '=%.0s' {1..60}
    echo

}

show_banner() {

    echo

    horizontal_rule

    printf "              %s\n" "$SG_NAME"
    printf "              Version %s\n" "$SG_VERSION"

    horizontal_rule

    echo

}

#===============================================================================
# VERIFICAÇÕES
#===============================================================================

require_root() {

    [[ $EUID -eq 0 ]] || die "Este comando deve ser executado como root."

}

command_exists() {

    command -v "$1" >/dev/null 2>&1

}

check_dependency() {

    local cmd="$1"

    if command_exists "$cmd"; then
        ok "Dependência encontrada: $cmd"
    else
        die "Dependência obrigatória ausente: $cmd"
    fi

}

#===============================================================================
# SISTEMA
#===============================================================================

detect_os() {

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$PRETTY_NAME"
        return 0
    fi

    echo "Sistema desconhecido"
    return 1

}

#===============================================================================
# ARQUIVOS
#===============================================================================

directory_exists() {

    [[ -d "$1" ]]

}

file_exists() {

    [[ -f "$1" ]]

}

create_directory() {

    local dir="$1"

    mkdir -p "$dir" || die "Não foi possível criar o diretório: $dir"

}

copy_file() {

    local source="$1"
    local target="$2"

    [[ -f "$source" ]] || die "Arquivo não encontrado: $source"

    cp -f "$source" "$target" || die "Erro ao copiar: $source"

}

make_executable() {

    chmod 755 "$1" || die "Não foi possível alterar permissões: $1"

}

#===============================================================================
# INTERAÇÃO
#===============================================================================

pause() {

    read -rp "Pressione ENTER para continuar..."

}

confirm() {

    local question="$1"
    local reply

    read -rp "$question [s/N]: " reply

    [[ "$reply" =~ ^[SsYy]$ ]]

}

#===============================================================================
# FIM DA BIBLIOTECA
#===============================================================================
