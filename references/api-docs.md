# Strava API Documentation Reference

## Authentication

### OAuth 2.0 Flow

1. **Authorization Request**
   ```
   GET https://www.strava.com/oauth/authorize
   ?client_id=YOUR_CLIENT_ID
   &response_type=code
   &redirect_uri=YOUR_REDIRECT_URI
   &scope=activity:write
   &approval_prompt=force
   ```

2. **Token Exchange**
   ```
   POST https://www.strava.com/oauth/token
   Content-Type: application/x-www-form-urlencoded

   client_id=YOUR_CLIENT_ID
   &client_secret=YOUR_CLIENT_SECRET
   &code=AUTHORIZATION_CODE
   &grant_type=authorization_code
   ```

3. **Token Refresh**
   ```
   POST https://www.strava.com/oauth/token
   Content-Type: application/x-www-form-urlencoded

   client_id=YOUR_CLIENT_ID
   &client_secret=YOUR_CLIENT_SECRET
   &refresh_token=REFRESH_TOKEN
   &grant_type=refresh_token
   ```

### Required Scopes

- `activity:write` - Create activities and upload files (REQUIRED for uploads)
- `activity:read_all` - Read all activities (optional)
- `profile:read_all` - Read full profile (optional)

## Uploads API

### Create Upload

**Endpoint:** `POST https://www.strava.com/api/v3/uploads`

**Required Parameters:**
- `file` - Binary file content (FIT, GPX, TCX)
- `data_type` - File format: `fit`, `gpx`, or `tcx`

**Optional Parameters:**
- `name` - Activity name
- `description` - Activity description
- `trainer` - `"0"` or `"1"` (indoor trainer)
- `commute` - `"0"` or `"1"` (commute ride)
- `data_type` - `fit`, `gpx`, `tcx`
- `external_id` - Custom identifier

**Example Request:**
```bash
curl -X POST https://www.strava.com/api/v3/uploads \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "file=@activity.fit" \
  -F "data_type=fit"
```

**Response:**
```json
{
  "id": 123456789,
  "id_str": "123456789",
  "external_id": "activity.fit",
  "error": null,
  "status": "Your activity is still being processed.",
  "activity_id": null
}
```

### Check Upload Status

**Endpoint:** `GET https://www.strava.com/api/v3/uploads/{uploadId}`

**Example:**
```bash
curl -X GET "https://www.strava.com/api/v3/uploads/123456789" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

**Response Statuses:**
- `"Your activity is still being processed."` - Processing
- `"Your activity is ready."` - Success
- `"There was an error processing your activity."` - Error

## Rate Limits

### Default Limits
- **Short term:** 100 requests every 15 minutes
- **Long term:** 1000 requests per day
- **Uploads:** 1 file per request (no batch upload)

### Headers
- `X-RateLimit-Limit` - Requests per 15 minutes
- `X-RateLimit-Usage` - Current usage
- `Retry-After` - Seconds to wait when limited

## Error Codes

### Common Errors

| Code | Description | Solution |
|------|-------------|----------|
| `401` | Unauthorized | Token expired or invalid |
| `403` | Forbidden | Insufficient permissions |
| `404` | Not Found | Resource doesn't exist |
| `429` | Too Many Requests | Rate limited, wait and retry |
| `500` | Internal Server Error | Strava server issue |

### Upload-Specific Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `missing activity:write_permission` | Token lacks upload scope | Re-authorize with `activity:write` |
| `duplicate of activity` | File already uploaded | Check existing activities |
| `File too large` | >25MB | Compress or split file |
| `Invalid file format` | Unsupported format | Convert to FIT/GPX/TCX |

## File Specifications

### FIT Format
- **Extension:** `.fit`
- **Max Size:** 25MB
- **Sources:** Garmin, Wahoo, other GPS devices
- **Metadata:** Includes activity type, GPS, heart rate, power, etc.

### GPX Format
- **Extension:** `.gpx`
- **Max Size:** 25MB
- **Standard:** GPS Exchange Format (XML)
- **Metadata:** GPS tracks, waypoints, routes

### TCX Format
- **Extension:** `.tcx`
- **Max Size:** 25MB
- **Standard:** Training Center XML (Garmin)
- **Metadata:** GPS, heart rate, cadence, power

## Best Practices

### Token Management
1. Store refresh tokens securely
2. Check token expiration before requests
3. Implement automatic refresh
4. Log token usage for debugging

### File Handling
1. Validate file size before upload
2. Check file format compatibility
3. Handle duplicate detection gracefully
4. Provide user feedback on processing status

### Error Handling
1. Implement retry logic for network errors
2. Handle rate limits with exponential backoff
3. Log detailed error information
4. Provide user-friendly error messages

## Testing

### Test Endpoints
```bash
# Test authentication
curl -X GET "https://www.strava.com/api/v3/athlete" \
  -H "Authorization: Bearer ACCESS_TOKEN"

# Test upload with small file
curl -X POST https://www.strava.com/api/v3/uploads \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "file=@test.fit" \
  -F "data_type=fit"
```

### Sample Files
- Small FIT file for testing
- Minimal GPX track
- Basic TCX activity

## Resources

### Official Documentation
- [Strava API v3 Docs](https://developers.strava.com/docs/reference/)
- [Authentication Guide](https://developers.strava.com/docs/authentication/)
- [Uploads API](https://developers.strava.com/docs/uploads/)

### Tools
- [API Playground](https://developers.strava.com/playground/) - Test API calls
- [Strava App Settings](https://www.strava.com/settings/api) - Manage credentials

### Community
- [Strava Developers Forum](https://community.strava.com/c/developers/6)
- [GitHub API Libraries](https://github.com/topics/strava-api)