#!/usr/bin/env bash
set -euo pipefail

echo "=== Orch Setup ==="
echo ""

# Check prerequisites
check_cmd() {
    if command -v "$1" &>/dev/null; then
        echo "  ✓ $1 found: $(command -v $1)"
    else
        echo "  ✗ $1 not found"
        MISSING+=("$1")
    fi
}

MISSING=()
echo "Checking prerequisites..."
check_cmd brew
check_cmd git

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "Missing required tools: ${MISSING[*]}"
    echo "Install them and re-run this script."
    exit 1
fi

# Install dependencies via brew
echo ""
echo "Installing dependencies..."
brew install go tmux gh 2>/dev/null || true

# Check Claude Code
if ! command -v claude &>/dev/null; then
    echo ""
    echo "  ✗ Claude Code CLI not found."
    echo "    Install it: npm install -g @anthropic-ai/claude-code"
    echo "    Then re-run this script."
    exit 1
fi
echo "  ✓ claude found: $(command -v claude)"

# Authenticate GitHub if needed
if ! gh auth status &>/dev/null 2>&1; then
    echo ""
    echo "GitHub CLI not authenticated. Run:"
    echo "  gh auth login"
    echo "Then re-run this script."
    exit 1
fi
echo "  ✓ gh authenticated"
gh auth setup-git

# Initialize submodules
echo ""
echo "Initializing submodules..."
cd "$(dirname "$0")"
git submodule update --init --recursive

# Build and install tools
echo ""
echo "Building linear-cli..."
cd tools/linear-cli
go build -o linear .
cp linear /usr/local/bin/linear
rm linear
echo "  ✓ linear installed at /usr/local/bin/linear"

echo ""
echo "Installing man pages..."
mkdir -p /usr/local/share/man/man1
cp man/*.1 /usr/local/share/man/man1/
echo "  ✓ man pages installed"

echo ""
echo "Building session-cli..."
cd ../session-cli
go build -o session .
cp session /usr/local/bin/session
rm session
echo "  ✓ session installed at /usr/local/bin/session"

cd ../..

# Set up .env if not present
if [ ! -f .env ] || ! grep -q "LINEAR_API_KEY=lin_" .env; then
    echo ""
    echo "=== API Keys ==="
    echo "Create a Linear API key at: https://linear.app/settings/api"
    read -p "LINEAR_API_KEY: " LINEAR_KEY
    echo "LINEAR_API_KEY=$LINEAR_KEY" > .env
    echo "  ✓ .env created"
else
    echo ""
    echo "  ✓ .env already configured"
fi

# Create inbox directory
mkdir -p inbox
echo "  ✓ inbox directory ready"

# Create src directory
mkdir -p "$HOME/src"
echo "  ✓ ~/src directory ready"

# Install watchdog launchd agent
echo ""
echo "Setting up watchdog..."
PLIST="$HOME/Library/LaunchAgents/dev.thunk.session-watchdog.plist"
cat > "$PLIST" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.thunk.session-watchdog</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/session</string>
        <string>watchdog</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/orch/inbox/watchdog-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/orch/inbox/watchdog-stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
</dict>
</plist>
PLISTEOF
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
echo "  ✓ watchdog installed (checks every 5 min)"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Run the test suite to verify everything works:"
echo "  ./test.sh"
echo ""
echo "Start the orchestrator:"
echo "  session orch"
