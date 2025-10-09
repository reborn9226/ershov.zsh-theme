#!/bin/bash

# Универсальный установщик eza (современная замена ls с иконками)
# Поддержка: Debian/Ubuntu, RHEL/Fedora/Alma/Rocky

set -e  # Завершить при ошибке

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[ИНФО]${NC} $1"
}

success() {
    echo -e "${GREEN}[ГОТОВО]${NC} $1"
}

error() {
    echo -e "${RED}[ОШИБКА]${NC} $1" >&2
    exit 1
}

# Проверка наличия sudo
if ! command -v sudo &> /dev/null; then
    error "Пакет 'sudo' не установлен. Установите его от root: apt install sudo"
fi

# Определяем ОС
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_LIKE=$ID_LIKE
else
    error "Не удалось определить дистрибутив"
fi

# Установка для Debian/Ubuntu
install_debian() {
    log "Добавление репозитория eza для Debian/Ubuntu..."
    sudo apt update
    sudo apt install -y wget gpg

    # Импорт ключа
    wget -qO- https://github.com/eza-community/eza/releases/latest/download/eza-deb.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/eza.gpg >/dev/null

    # Добавление репозитория
    echo "deb [arch=$(dpkg --print-architecture)] https://ppa.launchpadcontent.net/eza-community/eza/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/eza.list

    log "Установка eza..."
    sudo apt update
    sudo apt install -y eza
}

# Установка для RHEL/Fedora
install_redhat() {
    log "Установка eza для RHEL/Fedora..."
    if command -v dnf &> /dev/null; then
        # Fedora
        if [[ "$OS" == "fedora" ]]; then
            sudo dnf install -y 'dnf-command(copr)'
            sudo dnf copr enable -y eza-community/eza
            sudo dnf install -y eza
        # RHEL, Alma, Rocky
        else
            sudo dnf install -y epel-release
            sudo dnf install -y eza
        fi
    elif command -v yum &> /dev/null; then
        sudo yum install -y epel-release
        sudo yum install -y eza
    else
        error "Не найден пакетный менеджер (dnf/yum)"
    fi
}

# Основной поток
main() {
    log "Определение дистрибутива: $OS ($OS_LIKE)"

    if [[ "$OS" == "debian" || "$OS" == "ubuntu" || "$OS_LIKE" == *"debian"* ]]; then
        install_debian
    elif [[ "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "almalinux" || "$OS" == "rocky" || "$OS_LIKE" == *"rhel"* ]]; then
        install_redhat
    else
        error "Неподдерживаемый дистрибутив: $OS"
    fi

    success "eza установлен! Иконки в ls теперь доступны."
    echo
    echo -e "${BLUE}Чтобы включить иконки:${NC}"
    echo "1. Убедитесь, что в ~/.zshrc есть: USE_EZA=true"
    echo "2. Выполните: source ~/.zshrc"
}

main
