#!/bin/bash
set -e

SPEC="pubspec.yaml"

if [ ! -f "$SPEC" ]; then
  echo "pubspec.yaml not found in $(pwd)"
  exit 1
fi

CURRENT=$(grep "^version:" "$SPEC" | sed 's/version: //')
VER=$(echo "$CURRENT" | cut -d'+' -f1)
BUILD=$(echo "$CURRENT" | cut -d'+' -f2)

MAJOR=$(echo "$VER" | cut -d'.' -f1)
MINOR=$(echo "$VER" | cut -d'.' -f2)
PATCH=$(echo "$VER" | cut -d'.' -f3)
PATCH=$((PATCH + 1))

NEW_VER="$MAJOR.$MINOR.$PATCH"
NEW_BUILD=$((BUILD + 1))

sed -i "s/^version: .*/version: $NEW_VER+$NEW_BUILD/" "$SPEC"
echo "Bumped version: $CURRENT -> $NEW_VER+$NEW_BUILD"
