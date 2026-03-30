# Troubleshooting Guide

## Quick Diagnosis Flow

```
1. Check token status → ./scripts/strava-token-manager.sh check
2. Test API connection → ./scripts/strava-upload.sh test
3. Check file validity → file command, size check
4. Review logs → tail -f strava-upload.log
```

## Common Issues and Solutions

### Authentication Issues

#### 1. "Authorization Error" or "missing activity:write_permission"

**Symptoms:**
- API calls return 401 Unauthorized
- Upload fails with permission error
- `./scripts/strava-upload.sh test` shows connection but upload fails

**Causes:**
- Access token lacks `activity:write` scope
- Token expired and refresh failed
- Refresh token revoked by user

**Solutions:**

**A. Check current token scope:**
```bash
# Test basic API access (checks read permissions)
curl -s -X GET "https://www.strava.com/api/v3/athlete" \
  -H "Authorization: Bearer ACCESS_TOKEN" | jq '.id'

# Test upload permission (will fail if missing activity:write)
curl -s -X POST https://www.strava.com/api/v3/uploads \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "file=@test.fit" \
  -F "data_type=fit" | jq '.error'
```

**B. Re-authorize with correct scope:**
1. **Using API Playground (Recommended):**
   - Visit https://developers.strava.com/playground/
   - Click "Get Access" (top right)
   - **Ensure `activity:write` is checked**
   - Authorize and get new tokens

2. **Manual OAuth flow:**
   ```bash
   # Generate authorization URL
   echo "https://www.strava.com/oauth/authorize?client_id=CLIENT_ID&response_type=code&redirect_uri=http://localhost&scope=activity:write&approval_prompt=force"
   
   # Open in browser, authorize, get code from redirect URL
   # Exchange code for tokens
   curl -X POST https://www.strava.com/oauth/token \
     -d client_id=CLIENT_ID \
     -d client_secret=CLIENT_SECRET \
     -d code=AUTHORIZATION_CODE \
     -d grant_type=authorization_code
   ```

**C. Update configuration:**
```bash
# Update strava-config.json with new tokens
jq '.access_token = "NEW_ACCESS_TOKEN" | .refresh_token = "NEW_REFRESH_TOKEN" | .expires_at = NEW_EXPIRES_AT' \
  strava-config.json > tmp && mv tmp strava-config.json
```

#### 2. Token Refresh Fails

**Symptoms:**
- `./scripts/strava-token-manager.sh refresh` fails
- Log shows "Token refresh failed"
- API calls start failing after 6 hours

**Solutions:**
```bash
# 1. Check refresh token validity
curl -s -X POST https://www.strava.com/oauth/token \
  -d client_id=CLIENT_ID \
  -d client_secret=CLIENT_SECRET \
  -d refresh_token=REFRESH_TOKEN \
  -d grant_type=refresh_token | jq '.error'

# 2. If refresh token invalid, need re-authorization (see above)
# 3. Check client_id and client_secret are correct
# 4. Ensure network connectivity
```

### File Upload Issues

#### 1. "Duplicate of activity"

**Symptoms:**
- Upload succeeds but returns duplicate error
- Activity already exists on Strava
- File hash matches existing activity

**Solutions:**
```bash
# Check if it's truly a duplicate
# The error message includes link to existing activity

# Options:
# 1. Keep duplicate (if intentional)
# 2. Delete existing activity on Strava first
# 3. Modify file slightly to change hash:
#    - Add small GPS offset
#    - Change timestamp slightly
#    - Add metadata field

# Note: Strava's duplicate detection is based on file content hash
# Renaming file doesn't help
```

#### 2. "File too large" (>25MB)

**Symptoms:**
- Upload fails with size error
- File exceeds 25MB limit
- Common with long activities or high-frequency recording

**Solutions:**
```bash
# 1. Check file size
ls -lh activity.fit

# 2. Compress if GPX/TCX (FIT is already binary)
gzip -9 activity.gpx  # Creates activity.gpx.gz
# Note: Strava accepts .gz compressed files

# 3. Split long activity
# Using gpsbabel to split by time or distance
gpsbabel -i gpx -f long_activity.gpx -x track,split,time=3600 -o gpx -F part1.gpx
gpsbabel -i gpx -f long_activity.gpx -x track,split,time=3600d=3600 -o gpx -F part2.gpx

# 4. Reduce recording frequency on device
# Change from 1-second to 5-second recording
```

#### 3. "Invalid file format"

**Symptoms:**
- Upload fails with format error
- File extension doesn't match actual format
- Corrupted file

**Solutions:**
```bash
# 1. Identify actual file type
file activity.fit
# Should show: activity.fit: data (FIT file)

# 2. Check file headers
head -c 100 activity.fit | xxd | head -5

# 3. Validate FIT file
python3 -c "
try:
    import fitparse
    fit = fitparse.FitFile('activity.fit')
    print('Valid FIT file')
except Exception as e:
    print(f'Invalid: {e}')
"

# 4. Convert between formats if needed
# FIT to GPX: gpsbabel -i garmin_fit -f input.fit -o gpx -F output.gpx
# GPX to TCX: gpsbabel -i gpx -f input.gpx -o gtrnctr -F output.tcx
```

#### 4. Upload Stuck in Processing

**Symptoms:**
- Upload ID returned but status stays "processing"
- No activity_id after several minutes
- Status check shows still processing

**Solutions:**
```bash
# 1. Check status
./scripts/strava-upload.sh status UPLOAD_ID

# 2. Wait longer (processing can take 1-5 minutes)
sleep 300  # Wait 5 minutes

# 3. Check for hidden errors
curl -s -X GET "https://www.strava.com/api/v3/uploads/UPLOAD_ID" \
  -H "Authorization: Bearer ACCESS_TOKEN" | jq '.error'

# 4. If stuck >10 minutes, consider re-uploading
# Sometimes Strava processing gets stuck
```

### Network and API Issues

#### 1. Rate Limiting (429 Too Many Requests)

**Symptoms:**
- API returns 429 status code
- Headers show rate limit exceeded
- `Retry-After` header indicates wait time

**Solutions:**
```bash
# 1. Check rate limit headers
curl -I -X GET "https://www.strava.com/api/v3/athlete" \
  -H "Authorization: Bearer ACCESS_TOKEN" | grep -i "rate"

# 2. Implement exponential backoff
wait_time=$(curl -I ... | grep -i "retry-after" | cut -d' ' -f2)
sleep ${wait_time:-60}

# 3. Reduce request frequency
# - Batch operations
# - Cache responses
# - Implement client-side rate limiting

# 4. Monitor usage
# Strava limits: 100 requests/15min, 1000 requests/day
```

#### 2. Network Timeouts

**Symptoms:**
- curl fails with timeout
- Upload hangs then fails
- Intermittent connectivity

**Solutions:**
```bash
# 1. Increase timeout
curl --max-time 300 --connect-timeout 60 ...

# 2. Implement retry logic
for i in {1..3}; do
    if curl --max-time 300 ...; then
        break
    fi
    sleep $((i * 10))  # Exponential backoff: 10, 20, 30 seconds
done

# 3. Check network connectivity
ping -c 3 www.strava.com
curl -I https://www.strava.com

# 4. Use different network if possible
```

### Configuration Issues

#### 1. Missing Dependencies

**Symptoms:**
- Scripts fail with "command not found"
- jq or curl not installed
- Permission denied errors

**Solutions:**
```bash
# 1. Install required tools
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt-get install jq curl

# 2. Check installation
which jq
which curl
jq --version

# 3. Set execute permissions
chmod +x scripts/*.sh

# 4. Check PATH
echo $PATH
```

#### 2. Configuration File Issues

**Symptoms:**
- "Configuration file does not exist"
- JSON parsing errors
- Missing required fields

**Solutions:**
```bash
# 1. Check file exists and is readable
ls -la strava-config.json
cat strava-config.json | jq .

# 2. Validate JSON structure
jq -e '.client_id and .client_secret and .refresh_token' strava-config.json

# 3. Set correct permissions
chmod 600 strava-config.json  # Owner read/write only

# 4. Create template if missing
cat > strava-config.json << EOF
{
  "client_id": "",
  "client_secret": "",
  "refresh_token": "",
  "access_token": "",
  "expires_at": 0,
  "last_refresh": null,
  "user_id": null,
  "athlete_name": null
}
EOF
```

#### 3. Permission Denied

**Symptoms:**
- "Permission denied" when running scripts
- Cannot write to log file
- Cannot update configuration

**Solutions:**
```bash
# 1. Check file permissions
ls -la strava-*.sh
ls -la strava-config.json
ls -la strava-upload.log

# 2. Set correct permissions
chmod +x scripts/*.sh
chmod 600 strava-config.json
chmod 644 strava-upload.log  # Or 666 if need group write

# 3. Check directory permissions
ls -la .
chmod 755 .  # Ensure directory is traversable

# 4. Run as correct user
whoami
sudo -u correct_user ./scripts/strava-upload.sh test
```

## Debugging Techniques

### Enable Detailed Logging

```bash
# Add to scripts for debugging
set -x  # Enable command tracing
set -e  # Exit on error
set -o pipefail  # Catch pipe errors

# Or run with debug
bash -x ./scripts/strava-upload.sh upload activity.fit
```

### Check System Resources

```bash
# Monitor during upload
top -b -n 1 | head -20
df -h .  # Check disk space
free -h  # Check memory
```

### Test Step by Step

```bash
# 1. Test token
./scripts/strava-token-manager.sh check

# 2. Test API connection
./scripts/strava-upload.sh test

# 3. Test file
file activity.fit
ls -lh activity.fit

# 4. Manual upload test
curl -v -X POST https://www.strava.com/api/v3/uploads \
  -H "Authorization: Bearer $(./scripts/strava-token-manager.sh get)" \
  -F "file=@activity.fit" \
  -F "data_type=fit"
```

### Review Logs

```bash
# Tail logs in real-time
tail -f strava-upload.log

# Search for errors
grep -i error strava-upload.log
grep -i fail strava-upload.log

# Check recent activity
tail -50 strava-upload.log

# Analyze log patterns
awk '{print $1, $2}' strava-upload.log | sort | uniq -c | sort -rn
```

## Prevention Tips

### Regular Maintenance

1. **Monitor token expiration:**
   ```bash
   # Daily check
   ./scripts/strava-token-manager.sh check
   ```

2. **Rotate logs:**
   ```bash
   # Keep last 7 days
   find . -name "strava-upload.log.*" -mtime +7 -delete
   ```

3. **Backup configuration:**
   ```bash
   cp strava-config.json strava-config.json.backup.$(date +%Y%m%d)
   ```

### Best Practices

1. **Validate files before upload**
2. **Implement retry logic for transient errors**
3. **Monitor rate limit usage**
4. **Keep dependencies updated**
5. **Test after configuration changes**

### Monitoring

```bash
# Health check script
#!/bin/bash
echo "=== Strava Upload Health Check ==="
echo "Time: $(date)"
echo "Token: $(./scripts/strava-token-manager.sh check 2>&1)"
echo "Test: $(./scripts/strava-upload.sh test 2>&1 | tail -1)"
echo "Log size: $(wc -l strava-upload.log | awk '{print $1}') lines"
echo "Last error: $(grep -i error strava-upload.log | tail -1)"
```

## Getting Help

### Collect Debug Information

```bash
# Create debug report
debug_report="strava-debug-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "=== System Information ==="
    uname -a
    echo -e "\n=== Dependencies ==="
    which jq curl bash
    jq --version
    curl --version
    echo -e "\n=== Configuration ==="
    jq 'del(.client_secret, .access_token, .refresh_token)' strava-config.json
    echo -e "\n=== Recent Logs ==="
    tail -100 strava-upload.log
    echo -e "\n=== File System ==="
    ls -la strava-*.*
    echo -e "\n=== Network Test ==="
    curl -I https://www.strava.com 2>&1 | head -5
} > "$debug_report"
```

### Resources

- **Strava API Documentation:** https://developers.strava.com/docs/
- **API Playground:** https://developers.strava.com/playground/
- **Community Forum:** https://community.strava.com/c/developers/6
- **GitHub Issues:** Search for similar issues

### When to Contact Support

1. Persistent 500 errors from Strava API
2. Account-specific issues not covered here
3. Suspected API bugs or changes
4. Rate limit issues despite proper pacing

Include debug report when contacting support.