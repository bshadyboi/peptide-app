#!/usr/bin/env bash
# Fix "accessing build database" / mkdtemp DerivedData errors in Xcode.
set -euo pipefail
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
if [[ -d "$DERIVED" ]]; then
  rm -rf "$DERIVED"/PeptidePriceTracker-*
  echo "Cleared PeptidePriceTracker DerivedData."
else
  echo "No DerivedData folder found."
fi
echo "In Xcode: Product → Clean Build Folder (Shift+Cmd+K), then rebuild."
