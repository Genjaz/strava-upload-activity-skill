# Strava Upload Skill

Automatically upload fitness files (FIT, GPX, TCX) to Strava with token management and error handling.

**Languages:** English | [简体中文](README.zh-CN.md)

## Features

- ✅ **Automatic token management** - Refresh tokens before expiration
- ✅ **File validation** - Check format, size, and duplicates
- ✅ **Error handling** - Retry logic and detailed error messages
- ✅ **Logging** - Complete audit trail of all operations
- ✅ **Simple interface** - Just send files, everything else is automatic

## Quick Start

### 1. Install Dependencies
```bash
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt-get install jq curl
```

### 2. Setup Skill
```bash
# Run setup script
./scripts/setup.sh

# Configure credentials
# Edit strava-config.json with your:
# - client_id
# - client_secret  
# - refresh_token (with activity:write scope)
```

### 3. Test Configuration
```bash
./scripts/strava-upload.sh test
```

### 4. Upload Files
```bash
# Upload a FIT file
./scripts/strava-upload.sh upload activity.fit

# Check upload status
./scripts/strava-upload.sh status UPLOAD_ID
```

## Skill Structure

```
strava-upload-activity-skill/
├── SKILL.md                    # Main skill documentation
├── scripts/
│   ├── strava-token-manager.sh # Token management
│   ├── strava-upload.sh        # File upload
│   └── setup.sh               # Initial setup
├── references/
│   ├── api-docs.md            # API reference
│   ├── file-formats.md        # File format specs
│   └── troubleshooting.md     # Problem solving
└── assets/
    └── config-template.json   # Configuration template
```

## Usage Examples

### As a Skill in OpenClaw
When this skill is loaded, OpenClaw will automatically:
1. Detect fitness file attachments
2. Upload them to Strava
3. Return activity links

### Manual Usage
```bash
# Check token status
./scripts/strava-token-manager.sh check

# Refresh token
./scripts/strava-token-manager.sh refresh

# Upload file
./scripts/strava-upload.sh upload morning_run.fit

# Batch upload
for file in *.fit; do
    ./scripts/strava-upload.sh upload "$file"
    sleep 2  # Avoid rate limiting
done
```

## Configuration

### Required Credentials
1. **Strava Application** - Create at https://www.strava.com/settings/api
2. **Client ID & Secret** - From application settings
3. **Refresh Token** - With `activity:write` scope from API Playground

### Configuration File
```json
{
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "refresh_token": "your_refresh_token",
  "access_token": "",  # Auto-filled
  "expires_at": 0,     # Auto-updated
  "last_refresh": null # Auto-updated
}
```

## Supported File Formats

| Format | Extension | Max Size | Notes |
|--------|-----------|----------|-------|
| FIT | `.fit` | 25MB | Garmin/Wahoo devices |
| GPX | `.gpx` | 25MB | GPS Exchange Format |
| TCX | `.tcx` | 25MB | Garmin Training Center |

## Error Handling

The skill handles:
- ✅ Token expiration (auto-refresh)
- ✅ Network errors (retry with backoff)
- ✅ Rate limiting (wait and retry)
- ✅ File validation (size, format)
- ✅ Duplicate detection

## Monitoring

### Logs
- `strava-upload.log` - All operations with timestamps
- Check for errors: `grep -i error strava-upload.log`

### Token Status
```bash
./scripts/strava-token-manager.sh check
# Status: Token valid
# Remaining time: 21546 seconds
```

### Health Check
```bash
./scripts/strava-upload.sh test
# ✓ Token obtained successfully
# ✓ API connection successful
# Athlete: Your Name
```

## Troubleshooting

Common issues and solutions in `references/troubleshooting.md`:

1. **Authorization errors** - Re-authorize with correct scope
2. **File too large** - Compress or split
3. **Duplicate activities** - File already uploaded
4. **Rate limiting** - Reduce request frequency

## Security

- Configuration file: `chmod 600 strava-config.json`
- No credentials in logs
- Tokens refreshed automatically
- Network requests over HTTPS

## Development

### Adding Features
1. Edit scripts in `scripts/` directory
2. Update documentation in `references/`
3. Test with sample files
4. Update `SKILL.md` if workflow changes

### Testing
```bash
# Run all tests
./scripts/strava-upload.sh test

# Test with sample file
./scripts/strava-upload.sh upload test.fit

# Check logs
tail -f strava-upload.log
```

## License

This skill is provided as-is for use with OpenClaw. Strava API terms apply.

## GitHub Repository

This skill is available on GitHub: [https://github.com/Genjaz/strava-upload-activity-skill](https://github.com/Genjaz/strava-upload-activity-skill)

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Issues
Report issues on GitHub: [https://github.com/Genjaz/strava-upload-activity-skill/issues](https://github.com/Genjaz/strava-upload-activity-skill/issues)

## Support

- **Documentation:** See `references/` directory
- **Issues:** Check `troubleshooting.md` or GitHub Issues
- **Strava API:** https://developers.strava.com/docs/
- **Community:** OpenClaw developer community