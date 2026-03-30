#!/bin/bash
# Strava Upload Skill Setup Script

set -e  # Exit on error

echo "=== Strava Upload Skill Setup ==="
echo ""

# Check dependencies
echo "1. Checking dependencies..."
for cmd in jq curl; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "  ✓ $cmd installed"
    else
        echo "  ✗ $cmd not found"
        echo "    Please install:"
        echo "    - macOS: brew install $cmd"
        echo "    - Ubuntu: sudo apt-get install $cmd"
        exit 1
    fi
done

# Create necessary files
echo ""
echo "2. Setting up files..."

# Create config template if doesn't exist
if [ ! -f "strava-config.json" ]; then
    echo "  Creating strava-config.json template..."
    cat > strava-config.json << 'EOF'
{
  "client_id": "",
  "client_secret": "",
  "refresh_token": "",
  "access_token": "",
  "expires_at": 0,
  "last_refresh": null,
  "user_id": null,
  "athlete_name": null,
  "config_version": "1.0",
  "created_at": "2026-03-30T00:00:00Z",
  "scope": "activity:write"
}
EOF
    echo "  ✓ Created strava-config.json"
else
    echo "  ✓ strava-config.json already exists"
fi

# Create log file
touch strava-upload.log
echo "  ✓ Created strava-upload.log"

# Set permissions
echo ""
echo "3. Setting permissions..."
chmod +x scripts/*.sh
chmod 600 strava-config.json 2>/dev/null || true
chmod 644 strava-upload.log
echo "  ✓ Set script permissions"

# Test scripts
echo ""
echo "4. Testing scripts..."
if [ -f "scripts/strava-token-manager.sh" ]; then
    echo "  ✓ strava-token-manager.sh found"
else
    echo "  ✗ strava-token-manager.sh missing"
    exit 1
fi

if [ -f "scripts/strava-upload.sh" ]; then
    echo "  ✓ strava-upload.sh found"
else
    echo "  ✗ strava-upload.sh missing"
    exit 1
fi

# Configuration instructions
echo ""
echo "=== Configuration Required ==="
echo ""
echo "To complete setup, you need to:"
echo ""
echo "1. Get Strava API credentials:"
echo "   a. Visit https://www.strava.com/settings/api"
echo "   b. Create an application (if not already)"
echo "   c. Note your Client ID and Client Secret"
echo ""
echo "2. Get refresh token with activity:write permission:"
echo "   a. Visit https://developers.strava.com/playground/"
echo "   b. Click 'Get Access' (top right)"
echo "   c. CHECK 'activity:write' scope"
echo "   d. Authorize and copy the refresh_token"
echo ""
echo "3. Update strava-config.json with:"
echo "   - client_id: Your Client ID"
echo "   - client_secret: Your Client Secret"
echo "   - refresh_token: Your refresh token"
echo ""
echo "4. Test the setup:"
echo "   ./scripts/strava-upload.sh test"
echo ""
echo "5. Upload a file:"
echo "   ./scripts/strava-upload.sh upload your_file.fit"
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Fill in strava-config.json with your credentials"
echo "2. Test with: ./scripts/strava-upload.sh test"
echo "3. Upload a file: ./scripts/strava-upload.sh upload file.fit"
echo ""
echo "For help, see references/troubleshooting.md"