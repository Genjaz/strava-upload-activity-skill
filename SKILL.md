---
name: strava-upload-activity
description: Upload fitness files (FIT, GPX, TCX) to Strava automatically. Use when: (1) user sends fitness file attachments, (2) user asks to upload activities to Strava, (3) automating Strava uploads from devices. NOT for: reading Strava activities (use Strava API directly), analyzing workout data (use fitness analysis tools). Requires Strava API credentials with activity:write permission.
---

# Strava Upload Skill

Automatically upload fitness files to Strava with token management and error handling.

## When to Use

✅ **USE this skill when:**

- User sends FIT/GPX/TCX file attachments
- "Upload this to Strava"
- "Sync my workout to Strava"
- Automating Strava uploads from Garmin/Wahoo/other devices
- Batch uploading fitness files

❌ **DON'T use this skill when:**

- Reading Strava activities (use Strava API directly)
- Analyzing workout data (use fitness analysis tools)
- Managing Strava profile/settings
- Social features (kudos, comments)

## Quick Start

### 1. Initial Setup (One-time)

User needs to provide Strava API credentials:

```bash
# Get credentials from:
# 1. https://www.strava.com/settings/api → Client ID & Secret
# 2. https://developers.strava.com/playground/ → Refresh Token (with activity:write)
```

### 2. Configuration

Create `strava-config.json`:

```json
{
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET",
  "refresh_token": "YOUR_REFRESH_TOKEN",
  "access_token": "",
  "expires_at": 0,
  "last_refresh": null,
  "user_id": null,
  "athlete_name": null
}
```

### 3. Automatic Upload

When user sends a FIT file, automatically:
1. Detect file type
2. Check/refresh token if needed
3. Upload to Strava
4. Return activity link

## Core Components

### Token Management

The skill includes automatic token refresh:

```bash
# scripts/strava-token-manager.sh
# - Checks token expiration
# - Automatically refreshes using refresh_token
# - Updates configuration
```

### File Upload

```bash
# scripts/strava-upload.sh
# - Validates file format and size
# - Uploads with minimal parameters (file + data_type)
# - Monitors upload status
# - Returns activity link
```

## Workflow

### Step 1: Detect Fitness File

- Monitor for file attachments with extensions: `.fit`, `.gpx`, `.tcx`
- Validate file size (<25MB)
- Determine data_type from file extension

### Step 2: Ensure Valid Token

```bash
# Check token expiration
if token_expired:
    refresh_token()
    update_config()
```

### Step 3: Upload File

```bash
curl -X POST https://www.strava.com/api/v3/uploads \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "file=@file.fit" \
  -F "data_type=fit"
```

### Step 4: Handle Response

- Parse upload ID
- Monitor processing status
- Return activity link when ready
- Handle errors (duplicates, format issues, etc.)

## Configuration Files

### strava-config.json

Main configuration file storing:
- API credentials
- Current tokens
- User information
- Token expiration times

### strava-upload.log

Log file tracking:
- Upload attempts
- Token refreshes
- Errors and successes
- Timestamps for debugging

## Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Authorization Error` | Missing activity:write permission | Re-authorize with correct scope |
| `Duplicate activity` | File already uploaded | Inform user, show existing activity link |
| `File too large` | >25MB | Compress or split file |
| `Invalid file format` | Unsupported format | Convert to FIT/GPX/TCX |
| `Token expired` | Access token >6 hours old | Automatic refresh |

### Automatic Retry

- Network errors: 3 retries with exponential backoff
- Rate limiting: Wait and retry
- Token issues: Refresh and retry

## API Reference

### Required Permissions

- `activity:write` - For uploading files
- (Optional) `activity:read_all` - For reading activities
- (Optional) `profile:read_all` - For user info

### Endpoints Used

- `POST /oauth/token` - Token exchange/refresh
- `POST /api/v3/uploads` - File upload
- `GET /api/v3/uploads/{id}` - Upload status
- `GET /api/v3/athlete` - User verification

### Rate Limits

- 15-minute window: 100 requests
- Daily limits: 1000 requests
- Uploads: 1 file per request

## Examples

### Basic Upload

```
User: [sends morning_run.fit]
Assistant: ✅ Uploaded to Strava!
         Activity: https://www.strava.com/activities/123456
         File: morning_run.fit
         Status: Ready
```

### Batch Upload

```
User: [sends ride1.fit, ride2.fit, ride3.fit]
Assistant: 📦 Batch upload in progress...
         ✅ ride1.fit → Morning Ride
         ✅ ride2.fit → Afternoon Ride  
         ✅ ride3.fit → Evening Ride
         All 3 activities uploaded successfully!
```

### Error Response

```
User: [sends duplicate.fit]
Assistant: ⚠️ This file appears to be a duplicate
         Existing activity: https://www.strava.com/activities/123456
         Would you like to upload anyway? (may create duplicate)
```

## Advanced Features

### Smart File Naming

- Extract metadata from FIT files
- Use filename or timestamp
- Custom naming templates

### Activity Type Detection

- Auto-detect from file metadata
- Fallback to user specification
- Support: run, ride, hike, walk, swim, etc.

### Progress Tracking

- Real-time upload progress
- Processing status updates
- Email notifications (optional)

## Security

### Credential Storage

- Configuration file: `chmod 600`
- No credentials in logs
- Encrypted storage (optional)

### Token Security

- Access tokens: 6-hour lifetime
- Refresh tokens: Long-term, stored securely
- Automatic revocation on suspicion

## Maintenance

### Regular Tasks

- Monitor token expiration
- Clean up old log files
- Update Strava API changes
- Test with sample files

### Troubleshooting

1. Check `strava-upload.log` for errors
2. Verify token permissions with `./scripts/strava-upload.sh test`
3. Test API connection with `curl`
4. Check file format with `file` command

## References

For detailed information, see:
- [API Documentation](references/api-docs.md) - Complete Strava API reference
- [File Formats](references/file-formats.md) - FIT/GPX/TCX specifications
- [Troubleshooting](references/troubleshooting.md) - Common issues and solutions

## Quick Commands

```bash
# Test connection
./scripts/strava-upload.sh test

# Upload file
./scripts/strava-upload.sh upload file.fit

# Check token
./scripts/strava-token-manager.sh check

# Refresh token
./scripts/strava-token-manager.sh refresh
```

## Notes

- Files are uploaded as-is, Strava processes metadata
- No activity name/description by default (can be added)
- Private/public setting follows Strava defaults
- Supports manual overrides for all parameters
