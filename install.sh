#!/usr/bin/env bash
#
# ==========================================================
# SysGuardian Installer
# Version : 7.0.0-alpha1
# ==========================================================

set -Eeuo pipefail

############################################
# Variáveis
############################################

PROGRAM_NAME="SysGuardian"
PROGRAM_CMD="sysguardian"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="/usr/local/bin"
DATA_DIR="/usr/share/sysguardian"
CONFIG_DIR="/etc/sysguardian"
LOG_DIR="/var/log/sysguardian"

SRC_FILE="${PROJECT_ROOT}/src/sysguardian"
CONFIG_FILE="${PROJECT_ROOT}/config/sysguardian.conf"

############################################
# Cores
############################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

############################################
# Mensagens
############################################

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[ OK ]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

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
# Cabeçalho
############################################

show_banner() {

cat <<EOF

====================================================
              SysGuardian Installer
                 Version 7.0
====================================================

EOF

}

############################################
# Root
############################################

check_root() {

    if [[ $EUID -ne 0 ]]; then
        error "Execute este instalador com sudo."

        exit 1
    fi

    success "Permissões de administrador confirmadas."

}

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

    success "Estrutura do projeto validada."

}

############################################
# Detectar instalação
############################################

detect_installation() {

    if [[ -f "$BIN_DIR/$PROGRAM_CMD" ]]; then

        warning "Instalação existente encontrada."

        MODE="upgrade"

    else

        MODE="install"

    fi

    success "Modo: $MODE"

}

############################################
# Criar diretórios
############################################

create_directories() {

    info "Criando diretórios..."

    mkdir -p "$DATA_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"

    success "Diretórios criados."

}

############################################
# Backup da configuração
############################################

backup_config() {

    if [[ -f "$CONFIG_DIR/sysguardian.conf" ]]; then

        BACKUP="${CONFIG_DIR}/sysguardian.conf.bak.$(date +%Y%m%d-%H%M%S)"

        cp "$CONFIG_DIR/sysguardian.conf" "$BACKUP"

        warning "Backup criado:"

        echo "         $BACKUP"

    fi

}

############################################
# Instalar arquivos
############################################

install_files() {

    info "Instalando arquivos..."

    cp "$SRC_FILE" "$DATA_DIR/sysguardian"

    chmod 755 "$DATA_DIR/sysguardian"

    cp -r "$PROJECT_ROOT/modules" "$DATA_DIR/"
    cp -r "$PROJECT_ROOT/lib" "$DATA_DIR/"
    cp -r "$PROJECT_ROOT/templates" "$DATA_DIR/"

    cp "$PROJECT_ROOT/README.md" "$DATA_DIR/"
    cp "$PROJECT_ROOT/LICENSE" "$DATA_DIR/"
    cp "$PROJECT_ROOT/VERSION" "$DATA_DIR/"

    success "Arquivos instalados."

}

############################################
# Instalar configuração
############################################

install_config() {

    if [[ ! -f "$CONFIG_DIR/sysguardian.conf" ]]; then

        cp "$CONFIG_FILE" "$CONFIG_DIR/"

        success "Arquivo de configuração instalado."

    else

        warning "Configuração existente preservada."

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

chmod 755 "$BIN_DIR/$PROGRAM_CMD"

success "Comando '$PROGRAM_CMD' instalado."

}

############################################
# Permissões
############################################

set_permissions() {

    chmod -R 755 "$DATA_DIR"

    chmod 644 "$CONFIG_DIR/sysguardian.conf"

    success "Permissões configuradas."

}

############################################
# Validação
############################################

validate_installation() {

    info "Validando instalação..."

    command -v "$PROGRAM_CMD" >/dev/null

    success "Instalação validada."

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

    check_root

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
