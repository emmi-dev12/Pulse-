#!/usr/bin/env bash
set -euo pipefail

echo "Checking Pulse development environment..."

require() {
  if ! command -v "$1" &>/dev/null; then
    echo "  MISSING: $1 — $2"
    MISSING=1
  else
    echo "  OK:      $1"
  fi
}

MISSING=0

require xcode-select "Install Xcode from the App Store"
require brew       "Install Homebrew from https://brew.sh"
require xcodegen   "Run: brew install xcodegen"
require node       "Run: brew install node"
require npx        "Included with node"

if [ "$MISSING" -eq 0 ]; then
  echo ""
  echo "All dependencies present. Run 'make' to generate and open the Xcode project."
  echo "Run 'make convex-deploy' to deploy your Convex backend."
else
  echo ""
  echo "Install the missing tools above, then re-run this script."
  exit 1
fi
