#!/bin/bash

main() {
    local group_url="$1"
    local target_dir="${2:-$(pwd)}"
    
    # Проверка аргументов
    [ -z "$group_url" ] && { echo -e "\033[0;31mУкажите URL группы, например: bcli clone_group https://gitlab.com/mrvi0 [target_dir]\033[0m"; exit 1; }
    [ ! -d "$target_dir" ] && { echo -e "\033[0;31mДиректория $target_dir не существует\033[0m"; exit 1; }

    # Извлечение имени группы из URL
    local group_name
    group_name=$(echo "$group_url" | grep -oE '[^/]+$')
    [ -z "$group_name" ] && { echo -e "\033[0;31mНе удалось извлечь имя группы из $group_url\033[0m"; exit 1; }

    # Проверка зависимостей
    command -v curl >/dev/null 2>&1 || { echo -e "\033[0;31mТребуется curl\033[0m"; exit 1; }
    command -v git >/dev/null 2>&1 || { echo -e "\033[0;31mТребуется git\033[0m"; exit 1; }

    # Заголовок
    echo -e "\033[0;36m"
    echo "====================="
    echo "|       BCLI       |"
    echo "|    by mrvi0      |"
    echo "|-------------------|"
    echo "|  CLI for DevOps  |"
    echo "|  Fast & Simple   |"
    echo "====================="
    echo -e "\033[0m"

    # Получение ID группы через GitLab API
    local group_id
    if [ -n "$GITLAB_TOKEN" ]; then
        group_id=$(curl -sSL --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups?search=$group_name" | grep -B1 "\"full_path\":\"$group_name\"" | grep '"id"' | cut -d':' -f2 | cut -d',' -f1)
    else
        group_id=$(curl -sSL "https://gitlab.com/api/v4/groups?search=$group_name" | grep -B1 "\"full_path\":\"$group_name\"" | grep '"id"' | cut -d':' -f2 | cut -d',' -f1)
    fi
    [ -z "$group_id" ] && { echo -e "\033[0;31mНе удалось найти группу $group_name\033[0m"; exit 1; }

    # Получение списка репозиториев
    local api_url="https://gitlab.com/api/v4/groups/$group_id/projects"
    local repos
    if [ -n "$GITLAB_TOKEN" ]; then
        repos=$(curl -sSL --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$api_url" | grep '"http_url_to_repo"' | cut -d'"' -f4)
    else
        repos=$(curl -sSL "$api_url" | grep '"http_url_to_repo"' | cut -d'"' -f4)
    fi
    [ -z "$repos" ] && { echo -e "\033[0;31mНе удалось получить список репозиториев для $group_name\033[0m"; exit 1; }

    local cloned=0 skipped=0 errors=0

    # Клонирование репозиториев
    for repo_url in $repos; do
        local repo_name
        repo_name=$(basename "$repo_url" .git)
        local repo_dir="$target_dir/$repo_name"

        if [ -d "$repo_dir/.git" ]; then
            echo -ne "\r\033[K\033[0;33mПропускаю $repo_name — уже существует\033[0m"
            ((skipped++))
            sleep 0.1
            continue
        fi

        echo -ne "\r\033[K\033[0;36mКлонирую $repo_name...\033[0m"
        if git clone "$repo_url" "$repo_dir" >/dev/null 2>&1; then
            ((cloned++))
            echo -ne "\r\033[K\033[0;32m$repo_name: склонировано\033[0m"
        else
            ((errors++))
            echo -ne "\r\033[K\033[0;31m$repo_name: ошибка клонирования\033[0m"
        fi
        sleep 0.1
    done

    # Итоговый вывод
    echo -ne "\r\033[K"
    echo -e "\033[0;32mСклонировано: $cloned\033[0m"
    echo -e "\033[0;33mПропущено: $skipped\033[0m"
    echo -e "\033[0;31mОшибок: $errors\033[0m"
}