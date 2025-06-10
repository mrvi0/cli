#!/bin/bash

main() {
    local target_dir="$1"
    [ -z "$target_dir" ] && { echo -e "\033[0;31mУкажите директорию, например: bcli checkout_all /path\033[0m"; exit 1; }
    [ ! -d "$target_dir" ] && { echo -e "\033[0;31mДиректория $target_dir не существует\033[0m"; exit 1; }

    # Запрашиваем ветку
    read -p "Введите имя ветки: " BRANCH
    [ -z "$BRANCH" ] && { echo -e "\033[0;31mИмя ветки не указано\033[0m"; exit 1; }

    local updated=0 skipped=0 errors=0

    # Переходим в целевую директорию
    cd "$target_dir" || { echo -e "\033[0;31mНе удалось перейти в $target_dir\033[0m"; exit 1; }

    # Обрабатываем репозитории
    for dir in */; do
        [ -d "$dir/.git" ] || { echo -ne "\r\033[K\033[0;33mПропускаю $dir — не git-репозиторий\033[0m"; ((skipped++)); sleep 0.1; continue; }
        
        echo -ne "\r\033[K\033[0;36mОбработка $dir...\033[0m"
        cd "$dir" || { echo -ne "\r\033[K\033[0;31mОшибка перехода в $dir\033[0m"; ((errors++)); cd ..; continue; }

        git fetch origin >/dev/null 2>&1

        if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
            git checkout "$BRANCH" >/dev/null 2>&1 && { ((updated++)); echo -ne "\r\033[K\033[0;32m$dir: перешёл на $BRANCH\033[0m"; } || { ((errors++)); echo -ne "\r\033[K\033[0;31m$dir: ошибка checkout\033[0m"; }
        else
            echo -ne "\r\033[K\033[0;33m$dir: ветка $BRANCH не найдена локально, пробую из origin...\033[0m"
            if git checkout -t "origin/$BRANCH" >/dev/null 2>&1; then
                ((updated++))
                echo -ne "\r\033[K\033[0;32m$dir: перешёл на $BRANCH из origin\033[0m"
            else
                ((errors++))
                echo -ne "\r\033[K\033[0;31m$dir: ветка $BRANCH не найдена\033[0m"
            fi
        fi
        cd .. >/dev/null 2>&1
        sleep 0.1 # Для плавности вывода
    done

    # Итоговый вывод
    echo -ne "\r\033[K"
    echo -e "\033[0;32mОбновлено: $updated\033[0m"
    echo -e "\033[0;33mПропущено: $skipped\033[0m"
    echo -e "\033[0;31mОшибок: $errors\033[0m"
}