#!/bin/bash
BACKUP_DIR="${BACKUP_DIR:-/backup}"

if [ "$#" -ne 3 ]; then
    echo "Использование: $0 <папка> <порог_%> <M>"; exit 1
fi
TARGET_DIR="$1"; THRESHOLD_N="$2"; FILES_M="$3"

[[ "$THRESHOLD_N" =~ ^[0-9]+$ && "$THRESHOLD_N" -le 100 ]] || { echo "Ошибка: порог должен быть числом 0-100"; exit 1; }
[[ "$FILES_M" =~ ^[1-9][0-9]*$ ]] || { echo "Ошибка: M должно быть положительным числом"; exit 1; }
[ -d "$TARGET_DIR" ] || { echo "Ошибка: директория '$TARGET_DIR' не существует."; exit 1; }

CURRENT_USAGE=$(df --output=pcent "$TARGET_DIR" | tail -1 | tr -dc '0-9')
echo "Текущий размер: ${CURRENT_USAGE}%"

if [ "$CURRENT_USAGE" -gt "$THRESHOLD_N" ]; then
    echo "Превышен порог (${THRESHOLD_N}%)."
    mkdir -p "$BACKUP_DIR" 2>/dev/null || sudo mkdir -p "$BACKUP_DIR"

    mapfile -d '' FILES < <(find "$TARGET_DIR" -maxdepth 1 -type f -name '*.log' \
        -printf '%T@ %p\0' | sort -z -n | head -z -n "$FILES_M" | cut -z -d' ' -f2-)

    if [ "${#FILES[@]}" -eq 0 ]; then
        echo "Нет файлов для архивации."; exit 0
    fi
    ARCHIVE="$BACKUP_DIR/backup_logs_$(date +%Y%m%d_%H%M%S).tar.gz"
    if tar -czf "$ARCHIVE" "${FILES[@]}" 2>/dev/null || sudo tar -czf "$ARCHIVE" "${FILES[@]}"; then
        echo "Создан архив: $ARCHIVE"
    else
        echo "Ошибка архивации"; exit 1
    fi
else
    echo "Заполнение в норме."
fi
