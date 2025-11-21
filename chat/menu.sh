#!/bin/bash

# Sqwak Chat Client
# Simple terminal-based chat client

# Configuration
SERVER_URL="https://708df46d8baf.ngrok-free.app"
USERNAME=$(hostname)
MESSAGE_QUEUE_FILE="/tmp/sqwak_queue_${USERNAME}.txt"
REFRESH_INTERVAL=30

# Color codes for terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Terminal dimensions
LINES=$(tput lines)
COLS=$(tput cols)
MESSAGE_LINES=17
INPUT_LINES=2
HEADER_LINES=3

# State variables
SERVER_ONLINE=false
LAST_MESSAGES=""

# Cleanup function
cleanup() {
    tput cnorm
    stty echo
    clear
    exit 0
}

trap cleanup EXIT INT TERM

# Check if server is online
check_server() {
    if curl -fs --max-time 5 "${SERVER_URL}/health" > /dev/null 2>&1; then
        SERVER_ONLINE=true
        return 0
    else
        SERVER_ONLINE=false
        return 1
    fi
}

# Send message to server
send_message() {
    local message="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local json_payload=$(cat <<EOF
{
    "user": "${USERNAME}",
    "message": "${message}",
    "timestamp": "${timestamp}"
}
EOF
    )
    
    if check_server; then
        local response=$(curl -s -X POST -H "Content-Type: application/json" \
            -d "${json_payload}" "${SERVER_URL}/message" 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi
    
    # If we get here, server is down - queue the message
    echo "${json_payload}" >> "$MESSAGE_QUEUE_FILE"
    return 1
}

# Flush queued messages
flush_queued_messages() {
    if [[ ! -f "$MESSAGE_QUEUE_FILE" ]]; then
        return 0
    fi
    
    if check_server; then
        local temp_file="${MESSAGE_QUEUE_FILE}.tmp"
        > "$temp_file"  # Create empty temp file
        
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local response=$(curl -s -X POST -H "Content-Type: application/json" \
                    -d "${line}" "${SERVER_URL}/message" 2>/dev/null)
                
                if [[ $? -ne 0 ]]; then
                    # If send failed, keep the message
                    echo "$line" >> "$temp_file"
                fi
            fi
        done < "$MESSAGE_QUEUE_FILE"
        
        mv "$temp_file" "$MESSAGE_QUEUE_FILE"
        
        # If file is empty after flushing, remove it
        if [[ ! -s "$MESSAGE_QUEUE_FILE" ]]; then
            rm -f "$MESSAGE_QUEUE_FILE"
        fi
    fi
}

# Get messages from server
get_messages() {
    if check_server; then
        curl -s --max-time 10 "${SERVER_URL}/messages" 2>/dev/null
    else
        echo "[]"
    fi
}

# Parse and format messages
format_messages() {
    local messages_json="$1"
    local formatted=""
    
    # Very basic JSON parsing without jq
    # This is fragile but works for the expected format
    while IFS= read -r line; do
        if [[ $line =~ \"user\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
            local user="${BASH_REMATCH[1]}"
        fi
        
        if [[ $line =~ \"message\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
            local message="${BASH_REMATCH[1]}"
        fi
        
        if [[ $line =~ \"color\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
            local color="${BASH_REMATCH[1]}"
        fi
        
        if [[ -n "$user" && -n "$message" && -n "$color" ]]; then
            # Map color names to terminal colors
            case "$color" in
                "red") COLOR_CODE="$RED" ;;
                "green") COLOR_CODE="$GREEN" ;;
                "yellow") COLOR_CODE="$YELLOW" ;;
                "blue") COLOR_CODE="$BLUE" ;;
                "magenta") COLOR_CODE="$MAGENTA" ;;
                "cyan") COLOR_CODE="$CYAN" ;;
                "white") COLOR_CODE="$WHITE" ;;
                *) COLOR_CODE="$WHITE" ;;
            esac
            
            # Truncate long messages to fit screen
            local max_msg_len=$((COLS - ${#user} - 8))
            if [[ ${#message} -gt $max_msg_len ]]; then
                message="${message:0:$max_msg_len}..."
            fi
            
            formatted="${formatted}[${COLOR_CODE}${user}${NC}] ${message}\n"
            
            # Reset for next message
            user=""
            message=""
            color=""
        fi
    done < <(echo "$messages_json" | tr ',' '\n' | grep -E '(user|message|color)')
    
    echo -e "$formatted" | tail -n $MESSAGE_LINES
}

# Draw the UI
draw_ui() {
    clear
    
    # Header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}S Q W A K${NC} ${CYAN}│${NC} Chat Lobby ${CYAN}│                              ${NC} $([ "$SERVER_ONLINE" = true ] && echo -e "${GREEN}ON-LINE${NC}" || echo -e "${RED}OFFLINE${NC}") ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    # Messages area
    local messages=$(format_messages "$LAST_MESSAGES")
    echo -e "$messages"
    
    # Fill remaining message lines
    local current_msg_lines=$(echo -e "$messages" | wc -l)
    local empty_lines=$((MESSAGE_LINES - current_msg_lines))
    
    for ((i=0; i<empty_lines; i++)); do
        echo
    done
    
    # Input area separator
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}${USERNAME}${NC}: "
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
}

# Simple input function
get_user_input() {
    local input_line=$((HEADER_LINES + MESSAGE_LINES + 1))
    tput cup $input_line $((${#USERNAME} + 2))
    
    stty echo
    tput cnorm
    
    read -r user_input
    
    tput civis
    stty -echo
    
    echo "$user_input"
}

# Main chat loop
main() {
    # Initial setup
    tput civis
    stty -echo
    
    # Initial server check and message load
    check_server
    LAST_MESSAGES=$(get_messages)
    flush_queued_messages
    
    local last_refresh=$(date +%s)
    
    while true; do
        # Draw the interface
        draw_ui
        
        # Show input prompt
        tput cup $((HEADER_LINES + MESSAGE_LINES + 1)) $((${#USERNAME} + 4))
        stty echo
        tput cnorm
        
        # Get user input with simple read (with 1 second timeout to allow refresh check)
        if read -r -t 30 user_input; then
            tput civis
            stty -echo
            
            # Send message if not empty
            if [[ -n "$user_input" ]]; then
                send_message "$user_input"
                # Refresh messages immediately after sending
                LAST_MESSAGES=$(get_messages)
                flush_queued_messages
                last_refresh=$(date +%s)
            fi
        fi
        
        # Check if it's time to refresh (every 30 seconds)
        local current_time=$(date +%s)
        local time_since_refresh=$((current_time - last_refresh))
        
        if [[ $time_since_refresh -ge $REFRESH_INTERVAL ]]; then
            LAST_MESSAGES=$(get_messages)
            flush_queued_messages
            last_refresh=$current_time
        fi
    done
}

# Initialize message queue file
touch "$MESSAGE_QUEUE_FILE"

# Start the chat client
main