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
    local file_path=$(realpath "$1")
    if [ ! -f "$file_path" ]; then
        echo "Error: File does not exist."
        return
    fi
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local unique_id=$(generate_unique_id)

    cp "$file_path" "$STASH_DIR/$unique_id"
    echo "$timestamp,$unique_id,$file_path" >> "$LOG_FILE"
    rm "$file_path"
    echo "Stashed: $file_path with ID $unique_id"
}

function list_stashed_files() {
    echo "Date, ID, Original Path"
    cat "$LOG_FILE"
}

function restore_file() {
    local unique_id="$1"
    local line=$(grep ",$unique_id," "$LOG_FILE")

    if [ -n "$line" ]; then
        local original_path=$(echo "$line" | cut -d ',' -f3)
        if [ ! -f "$STASH_DIR/$unique_id" ]; then
            echo "Error: Stashed file does not exist."
            return
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
        echo "File not found."
    fi
}

case "$1" in
    s)
        ;&
    stash)
        stash_file "$2"
        ;;
    list)
        list_stashed_files
        ;;
    r)
        ;&
    restore)
        restore_file "$2"
        ;;
    help)
        echo "Usage: stash {stash|list|restore} [file_path|id]"
        ;;
    *)
        stash_file "$1"
        ;;
esac

