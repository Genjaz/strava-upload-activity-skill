# Strava Upload Skill - Package Information

## Skill Summary

**Name:** `strava-upload-activity`  
**Description:** Upload fitness files (FIT, GPX, TCX) to Strava automatically with token management and error handling.  
**Version:** 1.0.0  
**Created:** 2026-03-30  
**Author:** OpenClaw Assistant

## Contents

### Core Files
- `SKILL.md` - Main skill documentation and triggers
- `README.md` - User documentation

### Scripts (`scripts/`)
- `strava-token-manager.sh` - Automatic token refresh
- `strava-upload.sh` - File upload with validation
- `setup.sh` - Initial configuration helper

### References (`references/`)
- `api-docs.md` - Strava API reference
- `file-formats.md` - FIT/GPX/TCX specifications
- `troubleshooting.md` - Common issues and solutions

### Assets (`assets/`)
- `config-template.json` - Configuration template

## Skill Triggers

This skill activates when:
1. User sends fitness file attachments (.fit, .gpx, .tcx)
2. User asks to upload activities to Strava
3. Automating Strava uploads from devices

## Dependencies

### Required Tools
- `jq` - JSON processing
- `curl` - HTTP requests
- `bash` - Shell environment

### API Requirements
- Strava API credentials
- `activity:write` permission scope
- Valid refresh token

## Installation

### For OpenClaw Users
1. Place skill in OpenClaw skills directory
2. Ensure dependencies are installed
3. Configure `strava-config.json` with credentials
4. Skill will auto-trigger when needed

### Manual Usage
```bash
# 1. Install dependencies
brew install jq curl  # macOS
# or
apt-get install jq curl  # Linux

# 2. Run setup
./scripts/setup.sh

# 3. Configure
# Edit strava-config.json with your credentials

# 4. Test
./scripts/strava-upload.sh test

# 5. Use
./scripts/strava-upload.sh upload file.fit
```

## Testing

The skill has been tested with:
- ✅ FIT files from Garmin devices
- ✅ GPX exports from smartphone apps
- ✅ TCX files from older Garmin devices
- ✅ Token refresh mechanism
- ✅ Error handling and retry logic
- ✅ Rate limit management

## Security Considerations

1. **Credentials:** Stored in `strava-config.json` with `chmod 600`
2. **Tokens:** Auto-refreshed, never logged
3. **Network:** All requests over HTTPS
4. **Files:** Validated before upload

## Maintenance

### Regular Tasks
- Monitor token expiration
- Check Strava API for changes
- Update dependencies as needed
- Review logs for issues

### Updates
When updating the skill:
1. Test with sample files
2. Update documentation
3. Verify backward compatibility
4. Update version in SKILL.md

## Packaging

To create a distributable .skill file:

```bash
# Using skill-creator tools
scripts/package_skill.py strava-upload-activity-skill

# Or manually create zip
zip -r strava-upload-activity.skill strava-upload-activity-skill/*
```

## Distribution

This skill can be:
1. Shared as `.skill` file
2. Added to OpenClaw skill repository
3. Used as template for similar upload skills

## Support

For issues:
1. Check `references/troubleshooting.md`
2. Review `strava-upload.log`
3. Test with `./scripts/strava-upload.sh test`
4. Consult Strava API documentation

## Credits

- **Strava API** - https://developers.strava.com/
- **OpenClaw** - Skill framework
- **Community** - Testing and feedback

## Changelog

### v1.0.0 (2026-03-30)
- Initial release
- Automatic token management
- FIT/GPX/TCX file support
- Error handling and retry logic
- Comprehensive documentation