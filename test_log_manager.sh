#!/bin/bash
SCRIPT="./log_manager.sh"
T=$(mktemp -d); export BACKUP_DIR="$T/backup"
mkdir -p "$T/logs"
touch -d "2026-01-01" "$T/logs/old_1.log"
touch -d "2026-10-01" "$T/logs/new_1.log"
FAIL=0
check() { if [ "$2" = "$3" ]; then echo "PASS: $1"; else echo "FAIL: $1"; FAIL=1; fi; }

$SCRIPT /no/such 50 2 >/dev/null; check "нет папки -> exit 1" 1 $?
$SCRIPT >/dev/null;               check "без аргументов -> exit 1" 1 $?
$SCRIPT "$T/logs" abc 1 >/dev/null; check "порог не число -> exit 1" 1 $?
$SCRIPT "$T/logs" 100 1 >/dev/null; check "порог 100 -> архива нет" 0 "$(ls "$BACKUP_DIR" 2>/dev/null | wc -l)"
$SCRIPT "$T/logs" 0 1 >/dev/null;   check "порог 0 -> архив есть" 1 "$(ls "$BACKUP_DIR" | wc -l)"
A=$(ls "$BACKUP_DIR"/*.tar.gz)
check "в архиве старый файл" 1 "$(tar -tzf "$A" | grep -c old_1.log)"
check "в архиве нет нового" 0 "$(tar -tzf "$A" | grep -c new_1.log)"

rm -rf "$T"; exit $FAIL
