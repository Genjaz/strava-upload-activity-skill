#!/bin/bash
# Strava File Upload Script

CONFIG_FILE="strava-config.json"
LOG_FILE="strava-upload.log"
TOKEN_SCRIPT="./strava-token-manager.sh"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
    echo "$1"
}

# Get valid token
get_token() {
    local token=$("$TOKEN_SCRIPT" get)
    if [ $? -ne 0 ] || [ -z "$token" ]; then
        log "Error: Cannot get valid token"
        return 1
    fi
    echo "$token"
}

# Upload file to Strava (simplified, only required parameters)
upload_to_strava() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        log "Error: File does not exist: $file_path"
        return 1
    fi
    
    # Check file size (25MB limit)
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path")
    local max_size=$((25 * 1024 * 1024))  # 25MB
    
    if [ $file_size -gt $max_size ]; then
        log "Error: File too large ($((file_size/1024/1024))MB), Strava limit is 25MB"
        return 1
    fi
    
    # Determine file type (macOS compatible)
    local file_ext="${file_path##*.}"
    local data_type=""
    
    # macOS bash doesn't support ${var,,}, use tr to convert to lowercase
    local file_ext_lower=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')
    
    case "$file_ext_lower" in
        fit) data_type="fit" ;;
        gpx) data_type="gpx" ;;
        tcx) data_type="tcx" ;;
        *) 
            log "Warning: Unknown file extension .$file_ext, attempting auto-detection"
            data_type="fit"  # Default to FIT
            ;;
    esac
    
    # Get valid token
    local access_token=$(get_token)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    log "Starting upload: $file_path (format: $data_type)"
    
    # Build upload command - only required parameters
    local curl_cmd="curl -s -X POST https://www.strava.com/api/v3/uploads"
    curl_cmd="$curl_cmd -H 'Authorization: Bearer $access_token'"
    curl_cmd="$curl_cmd -F 'file=@$file_path'"
    curl_cmd="$curl_cmd -F 'data_type=$data_type'"
    # Note: Not passing activity_type or other parameters, Strava auto-detects
    
    # Execute upload
    log "Executing upload command..."
    local response=$(eval "$curl_cmd")
    
    if echo "$response" | jq -e '.id' >/dev/null 2>&1; then
        local upload_id=$(echo "$response" | jq -r '.id')
        local activity_id=$(echo "$response" | jq -r '.activity_id // empty')
        local status=$(echo "$response" | jq -r '.status')
        
        log "Upload successful! Upload ID: $upload_id, Status: $status"
        
        if [ -n "$activity_id" ] && [ "$activity_id" != "null" ]; then
            log "Activity created: https://www.strava.com/activities/$activity_id"
            echo "https://www.strava.com/activities/$activity_id"
        else
            log "Activity processing, upload ID: $upload_id"
            echo "$upload_id"
        fi
        return 0
    else
        local error=$(echo "$response" | jq -r '.message // .error // "Unknown error"')
        log "Upload failed: $error"
        echo "$error"
        return 1
    fi
}

# Check upload status
check_upload_status() {
    local upload_id="$1"
    local access_token=$(get_token)
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local response=$(curl -s -X GET "https://www.strava.com/api/v3/uploads/$upload_id" \
        -H "Authorization: Bearer $access_token")
    
    if echo "$response" | jq -e '.id' >/dev/null 2>&1; then
        local status=$(echo "$response" | jq -r '.status')
        local activity_id=$(echo "$response" | jq -r '.activity_id // empty')
        local error=$(echo "$response" | jq -r '.error // empty')
        
        echo "Status: $status"
        if [ -n "$activity_id" ] && [ "$activity_id" != "null" ]; then
            echo "Activity ID: $activity_id"
            echo "Link: https://www.strava.com/activities/$activity_id"
        fi
        if [ -n "$error" ] && [ "$error" != "null" ]; then
            echo "Error: $error"
        fi
        return 0
    else
        echo "Cannot get upload status"
        return 1
    fi
}

# Main function
main() {
    case "$1" in
        "upload")
            if [ $# -lt 2 ]; then
                echo "Usage: $0 upload <file_path>"
                echo "Note: Only required parameters (file and data_type), Strava auto-detects activity type"
                exit 1
            fi
            upload_to_strava "$2"
            ;;
        "status")
            if [ $# -lt 2 ]; then
                echo "Usage: $0 status <upload_id>"
                exit 1
            fi
            check_upload_status "$2"
            ;;
        "test")
            echo "Testing connection..."
            local token=$(get_token)
            if [ $? -eq 0 ]; then
                echo "✓ Token obtained successfully"
                echo "Current token: ${token:0:20}..."
                
                # Test API connection
                local response=$(curl -s -X GET "https://www.strava.com/api/v3/athlete" \
                    -H "Authorization: Bearer $token")
                
                if echo "$response" | jq -e '.id' >/dev/null 2>&1; then
                    local athlete_name=$(echo "$response" | jq -r '.firstname + " " + .lastname')
                    echo "✓ API connection successful"
                    echo "Athlete: $athlete_name"
                    
                    # Update user info in config file
                    local user_id=$(echo "$response" | jq -r '.id')
                    jq --arg id "$user_id" --arg name "$athlete_name" \
                       '.user_id = ($id | tonumber) | .athlete_name = $name' \
                       "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                else
                    echo "✗ API connection failed"
                fi
            else
                echo "✗ Failed to get token"
            fi
            ;;
        *)
            echo "Strava File Upload Tool (Simplified)"
            echo "Usage: $0 {upload|status|test}"
            echo ""
            echo "Commands:"
            echo "  upload <file>          Upload file to Strava (auto-detect type)"
            echo "  status <upload_id>     Check upload status"
            echo "  test                   Test connection and configuration"
            echo ""
            echo "Notes:"
            echo "  - Only required parameters: file and data_type"
            echo "  - Strava auto-detects activity type, name, etc."
            echo "  - Supported formats: .fit, .gpx, .tcx"
            echo ""
            echo "Examples:"
            echo "  $0 upload morning_run.fit"
            echo "  $0 upload weekend_ride.fit"
            echo "  $0 status 123456789"
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