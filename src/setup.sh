#!/usr/bin/env bash

# Конфигурация
REPO="mrvi0/cli"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/src"
INSTALL_DIR="$HOME/.bcli"
MODULES_DIR="$INSTALL_DIR/modules"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Проверка зависимостей
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Требуется curl${NC}"; exit 1; }

# Создание директорий
mkdir -p "$INSTALL_DIR" "$MODULES_DIR"

# Загрузка главного скрипта
echo -e "${CYAN}Устанавливаю BCLI...${NC}"
curl -sSL "$BASE_URL/bcli" -o "$INSTALL_DIR/bcli"
chmod +x "$INSTALL_DIR/bcli"

# Загрузка модулей
echo -e "${CYAN}Загружаю модули...${NC}"
MODULES=$(curl -sSL "https://api.github.com/repos/$REPO/contents/src/modules?ref=$BRANCH" | grep '"name"' | cut -d'"' -f4 | cut -d'.' -f1)
for mod in $MODULES; do
    curl -sSL "$BASE_URL/modules/$mod.sh" -o "$MODULES_DIR/$mod.sh" 2>/dev/null
    [ -f "$MODULES_DIR/$mod.sh" ] && chmod +x "$MODULES_DIR/$mod.sh" || echo -e "${RED}Модуль $mod не найден${NC}"
done

# Настройка alias
if ! grep -q "alias bcli=" "$HOME/.bashrc"; then
    echo "alias bcli='$INSTALL_DIR/bcli'" >> "$HOME/.bashrc"
    echo -e "${GREEN}Добавлен alias в ~/.bashrc${NC}"
fi

echo -e "${GREEN}Установка завершена!${NC}"
echo -e "Выполните ${CYAN}source ~/.bashrc${NC} или перелогиньтесь"
echo -e "Проверьте: ${CYAN}bcli${NC}"