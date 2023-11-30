#!/bin/bash

STASH_DIR="$HOME/.file_stash"
LOG_FILE="$STASH_DIR/.stash_log.txt"
mkdir -p "$STASH_DIR"
touch $LOG_FILE

# Function to generate a unique 4-digit ID
function generate_unique_id() {
    while true; do
        local id=$((RANDOM % 10000))
        if ! grep -q "^.*,$id," "$LOG_FILE"; then
            echo $id
            return
        fi
    done
}

function stash_file() {
    for file_path in "$@"; do
        local real_path=$(realpath "$file_path")
        if [ ! -f "$real_path" ]; then
            echo "Error: File $file_path does not exist."
            continue
        fi
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local unique_id=$(generate_unique_id)

        cp "$real_path" "$STASH_DIR/$unique_id"
        echo "$timestamp,$unique_id,$real_path" >> "$LOG_FILE"
        rm "$real_path"
        echo "Stashed: $real_path with ID $unique_id"
    done
}

function list_stashed_files() {
    echo "Date, ID, Original Path"
    cat "$LOG_FILE"
}

function restore_file() {
    for unique_id in "$@"; do
        local line=$(grep ",$unique_id," "$LOG_FILE")

        if [ -n "$line" ]; then
            local original_path=$(echo "$line" | cut -d ',' -f3)
            if [ ! -f "$STASH_DIR/$unique_id" ]; then
                echo "Error: Stashed file $unique_id does not exist."
                continue
            fi
            mv "$STASH_DIR/$unique_id" "$original_path"
            grep -v ",$unique_id," "$LOG_FILE" > "$LOG_FILE.tmp"
            if [ -s "$LOG_FILE.tmp" ]; then
                mv "$LOG_FILE.tmp" "$LOG_FILE"
            else
                rm "$LOG_FILE.tmp" "$LOG_FILE"
            fi
            echo "Restored: $original_path"
        else
            echo "File with ID $unique_id not found."
        fi
    done
}

function clear_stash() {
    rm -rf "$STASH_DIR"/*
    > "$LOG_FILE"
    echo "Stash cleared."
}

function remove_ids() {
    for unique_id in "$@"; do
        if grep -q ",$unique_id," "$LOG_FILE"; then
            rm -f "$STASH_DIR/$unique_id"
            grep -v ",$unique_id," "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
            echo "Removed ID: $unique_id"
        else
            echo "ID $unique_id not found."
        fi
    done
}

case "$1" in
    s)
        ;&
    stash)
        shift
        stash_file "$@"
        ;;
    list)
        list_stashed_files
        ;;
    r)
        ;&
    restore)
        shift
        restore_file "$@"
        ;;
    clear)
        clear_stash
        ;;
    remove)
        shift
        remove_ids "$@"
        ;;
    help)
        echo "Usage: stash {stash|list|restore|clear|remove} [file_path|id]..."
        ;;
    *)
        stash_file "$@"
        ;;
esac

