#!/bin/bash

# Универсальный установщик FiraCode Nerd Font
# Поддержка: Debian/Ubuntu, RHEL/Fedora/Alma/Rocky

set -e  # Завершить при ошибке

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Определяем ОС
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_LIKE=$ID_LIKE
else
    error "Не удалось определить дистрибутив"
fi

# Устанавливаем зависимости
install_deps_debian() {
    log "Установка зависимостей для Debian/Ubuntu..."
    sudo apt update
    sudo apt install -y wget fontconfig
}

install_deps_redhat() {
    log "Установка зависимостей для RHEL/Fedora..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y wget fontconfig
    elif command -v yum &> /dev/null; then
        sudo yum install -y wget fontconfig
    else
        error "Не найден пакетный менеджер (dnf/yum)"
    fi
}

# Скачиваем и устанавливаем шрифты
install_fonts() {
    local FONT_DIR="/usr/local/share/fonts/nerd-fonts"
    local TMP_DIR="/tmp/firacode-nerd-fonts"

    log "Создание директорий..."
    sudo mkdir -p "$FONT_DIR"
    mkdir -p "$TMP_DIR"

    log "Скачивание FiraCode Nerd Font..."
    cd "$TMP_DIR"
    # Используем последнюю версию с GitHub Releases
    wget -q --show-progress -O firacode.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip \
        || error "Не удалось скачать шрифты"

    log "Распаковка..."
    unzip -q firacode.zip

    log "Копирование шрифтов в системную директорию..."
    sudo cp *.ttf "$FONT_DIR/" 2>/dev/null || true
    sudo cp *.otf "$FONT_DIR/" 2>/dev/null || true

    # Очистка
    cd /
    rm -rf "$TMP_DIR"

    log "Обновление кэша шрифтов..."
    sudo fc-cache -fv > /dev/null

    success "FiraCode Nerd Font установлен!"
    echo
    echo -e "${BLUE}Чтобы использовать шрифт:${NC}"
    echo "1. Откройте настройки вашего терминала (GNOME Terminal, Konsole, Alacritty и т.д.)"
    echo "2. Выберите шрифт: 'FiraCode Nerd Font' или 'FiraCode Nerd Font Mono'"
    echo "3. Перезапустите терминал"
}

# Основной поток
main() {
    log "Определение дистрибутива: $OS ($OS_LIKE)"

    if [[ "$OS" == "debian" || "$OS" == "ubuntu" || "$OS_LIKE" == *"debian"* ]]; then
        install_deps_debian
    elif [[ "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "almalinux" || "$OS" == "rocky" || "$OS_LIKE" == *"rhel"* ]]; then
        install_deps_redhat
    else
        error "Неподдерживаемый дистрибутив: $OS"
    fi

    install_fonts
}

# Запуск
main
