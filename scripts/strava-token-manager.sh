#!/bin/bash
# Strava Token Manager - Automatic access token refresh

CONFIG_FILE="strava-config.json"
LOG_FILE="strava-upload.log"

# Read configuration
read_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file $CONFIG_FILE does not exist"
        exit 1
    fi
    
    CLIENT_ID=$(jq -r '.client_id' "$CONFIG_FILE")
    CLIENT_SECRET=$(jq -r '.client_secret' "$CONFIG_FILE")
    REFRESH_TOKEN=$(jq -r '.refresh_token' "$CONFIG_FILE")
    ACCESS_TOKEN=$(jq -r '.access_token' "$CONFIG_FILE")
    EXPIRES_AT=$(jq -r '.expires_at' "$CONFIG_FILE")
}

# Check if token is expired
is_token_expired() {
    local current_time=$(date +%s)
    local buffer_time=300  # 5-minute buffer
    
    if [ "$EXPIRES_AT" = "null" ] || [ -z "$EXPIRES_AT" ] || [ "$EXPIRES_AT" = "0" ]; then
        return 0  # Consider expired
    fi
    
    if [ $((EXPIRES_AT - buffer_time)) -le $current_time ]; then
        return 0  # Expired or about to expire
    else
        return 1  # Still valid
    fi
}

# Refresh access token
refresh_access_token() {
    echo "$(date): Refreshing Strava access token..." >> "$LOG_FILE"
    
    local response=$(curl -s -X POST https://www.strava.com/oauth/token \
        -d client_id="$CLIENT_ID" \
        -d client_secret="$CLIENT_SECRET" \
        -d refresh_token="$REFRESH_TOKEN" \
        -d grant_type=refresh_token)
    
    if echo "$response" | jq -e '.access_token' >/dev/null 2>&1; then
        local new_access_token=$(echo "$response" | jq -r '.access_token')
        local new_expires_at=$(echo "$response" | jq -r '.expires_at')
        local new_refresh_token=$(echo "$response" | jq -r '.refresh_token')
        
        # Update configuration file
        jq --arg token "$new_access_token" \
           --arg expires "$new_expires_at" \
           --arg refresh "$new_refresh_token" \
           '.access_token = $token | .expires_at = ($expires | tonumber) | .refresh_token = $refresh | .last_refresh = now' \
           "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        echo "$(date): Token refreshed successfully, valid until $(date -r $new_expires_at)" >> "$LOG_FILE"
        echo "$new_access_token"
        return 0
    else
        echo "$(date): Token refresh failed: $response" >> "$LOG_FILE"
        return 1
    fi
}

# Get valid token (auto-refresh)
get_valid_token() {
    read_config
    
    if is_token_expired; then
        echo "Token expired, refreshing..." >&2
        refresh_access_token
    else
        echo "Token valid, remaining time: $((EXPIRES_AT - $(date +%s))) seconds" >&2
        echo "$ACCESS_TOKEN"
    fi
}

# Main function
main() {
    case "$1" in
        "check")
            read_config
            if is_token_expired; then
                echo "Status: Token expired"
                exit 1
            else
                echo "Status: Token valid"
                echo "Remaining time: $((EXPIRES_AT - $(date +%s))) seconds"
                exit 0
            fi
            ;;
        "refresh")
            read_config
            refresh_access_token
            ;;
        "get")
            get_valid_token
            ;;
        "test")
            read_config
            echo "Client ID: $CLIENT_ID"
            echo "Access Token: ${ACCESS_TOKEN:0:20}..."
            echo "Expires at: $(date -r $EXPIRES_AT)"
            echo "Refresh Token: ${REFRESH_TOKEN:0:20}..."
            ;;
        *)
            echo "Usage: $0 {check|refresh|get|test}"
            exit 1
            ;;
    esac
}

# Check for jq installation
if ! command -v jq &> /dev/null; then
    echo "Error: jq command is required"
    echo "Install: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

main "$@"