#!/usr/bin/env bash
#
# ==========================================================
# SysGuardian Installer
# Version : 7.0.0-alpha1
# ==========================================================

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/lib/core.sh"

############################################
# Variáveis
############################################

# PROGRAM_NAME="SysGuardian"
PROGRAM_CMD="sysguardian"

BIN_DIR="/usr/local/bin"
DATA_DIR="/usr/share/sysguardian"
CONFIG_DIR="/etc/sysguardian"
LOG_DIR="/var/log/sysguardian"

SRC_FILE="${PROJECT_ROOT}/src/sysguardian"
CONFIG_FILE="${PROJECT_ROOT}/config/sysguardian.conf"

############################################
# Erros
############################################

cleanup_on_error() {
    error "A instalação foi interrompida."

    echo
    echo "Revise a mensagem acima."
    exit 1
}

trap cleanup_on_error ERR

############################################
# Projeto
############################################

check_project() {

    info "Verificando estrutura do projeto..."

    local required=(
        "$SRC_FILE"
        "$CONFIG_FILE"
        "$PROJECT_ROOT/modules"
        "$PROJECT_ROOT/lib"
        "$PROJECT_ROOT/templates"
    )

    for item in "${required[@]}"; do

        [[ -e "$item" ]] || {

            error "Arquivo ausente: $item"
            exit 1

        }

    done

    ok "Estrutura do projeto validada."

}

############################################
# Detectar instalação
############################################

detect_installation() {

    if [[ -f "$BIN_DIR/$PROGRAM_CMD" ]]; then

        warn "Instalação existente encontrada."

        MODE="upgrade"

    else

        MODE="install"

    fi

    ok "Modo: $MODE"

}

############################################
# Criar diretórios
############################################

create_directories() {

    info "Criando diretórios..."

    create_directory "$DATA_DIR"
    create_directory "$CONFIG_DIR"
    create_directory "$LOG_DIR"

    ok "Diretórios criados."

}

############################################
# Backup da configuração
############################################

backup_config() {

    if [[ -f "$CONFIG_DIR/sysguardian.conf" ]]; then

        BACKUP="${CONFIG_DIR}/sysguardian.conf.bak.$(date +%Y%m%d-%H%M%S)"

        cp "$CONFIG_DIR/sysguardian.conf" "$BACKUP"

        warn "Backup criado:"

        echo "         $BACKUP"

    fi

}

############################################
# Instalar arquivos
############################################

install_files() {

    info "Instalando arquivos..."

    copy_file "$SRC_FILE" "$DATA_DIR/sysguardian"

    make_executable "$DATA_DIR/sysguardian"

    cp -r "$PROJECT_ROOT/modules" "$DATA_DIR/"
    cp -r "$PROJECT_ROOT/lib" "$DATA_DIR/"
    cp -r "$PROJECT_ROOT/templates" "$DATA_DIR/"

    cp "$PROJECT_ROOT/README.md" "$DATA_DIR/"
    cp "$PROJECT_ROOT/LICENSE" "$DATA_DIR/"
    cp "$PROJECT_ROOT/VERSION" "$DATA_DIR/"

    ok "Arquivos instalados."

}

############################################
# Instalar configuração
############################################

install_config() {

    if [[ ! -f "$CONFIG_DIR/sysguardian.conf" ]]; then

        cp "$CONFIG_FILE" "$CONFIG_DIR/"

        ok "Arquivo de configuração instalado."

    else

        warn "Configuração existente preservada."

    fi

}

############################################
# Criar comando
############################################

create_launcher() {

cat > "$BIN_DIR/$PROGRAM_CMD" <<EOF
#!/usr/bin/env bash

exec "$DATA_DIR/sysguardian" "\$@"
EOF

make_executable "$BIN_DIR/$PROGRAM_CMD"

ok "Comando '$PROGRAM_CMD' instalado."

}

############################################
# Permissões
############################################

set_permissions() {

    chmod -R 755 "$DATA_DIR"

    chmod 644 "$CONFIG_DIR/sysguardian.conf"

    ok "Permissões configuradas."

}

############################################
# Validação
############################################

validate_installation() {

    info "Validando instalação..."

    command -v "$PROGRAM_CMD" >/dev/null

    ok "Instalação validada."

}

############################################
# Resumo
############################################

show_summary() {

cat <<EOF

====================================================
           Instalação concluída com sucesso
====================================================

Comando:

    sudo $PROGRAM_CMD

Configuração:

    $CONFIG_DIR/sysguardian.conf

Relatórios:

    $LOG_DIR

Arquivos do programa:

    $DATA_DIR

====================================================

EOF

}

############################################
# Main
############################################

main() {

    show_banner

    require_root

    ok "Permissões de administrador confirmadas."

    check_project

    detect_installation

    backup_config

    create_directories

    install_files

    install_config

    create_launcher

    set_permissions

    validate_installation

    show_summary

}

main "$@"
