#!/bin/bash

# Build and Release Script for RoguePickPocketTracker
# Usage: ./buildAndRelease.sh

set -e  # Exit on any error

echo "🚀 RoguePickPocketTracker - Build and Release Script"
echo "=================================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Warning: You have uncommitted changes!"
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Please commit your changes first."
        exit 1
    fi
fi

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "📦 Latest tag: $LATEST_TAG"

# Parse the version from the latest tag (remove v prefix and any suffix like -alpha)
CLEAN_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//' | sed 's/-.*$//')

# Split version into components
IFS='.' read -ra VERSION_PARTS <<< "$CLEAN_VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

echo "📋 Current version: $MAJOR.$MINOR.$PATCH"
echo ""

# Ask for version bump type
echo "🔢 What type of version bump?"
echo "1) Patch (bug fixes): $MAJOR.$MINOR.$((PATCH+1))"
echo "2) Minor (new features): $MAJOR.$((MINOR+1)).0"
echo "3) Major (breaking changes): $((MAJOR+1)).0.0"
echo "4) Custom version"
echo ""

while true; do
    read -p "Select version bump type (1-4): " VERSION_TYPE
    case $VERSION_TYPE in
        1)
            NEW_VERSION="$MAJOR.$MINOR.$((PATCH+1))"
            break
            ;;
        2)
            NEW_VERSION="$MAJOR.$((MINOR+1)).0"
            break
            ;;
        3)
            NEW_VERSION="$((MAJOR+1)).0.0"
            break
            ;;
        4)
            read -p "Enter custom version (e.g., 1.2.3): " CUSTOM_VERSION
            if [[ $CUSTOM_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                NEW_VERSION="$CUSTOM_VERSION"
                break
            else
                echo "❌ Invalid version format. Please use x.y.z format."
            fi
            ;;
        *)
            echo "❌ Invalid selection. Please choose 1-4."
            ;;
    esac
done

echo ""
echo "🏷️  New version will be: $NEW_VERSION"
echo ""

# Ask for release type
echo "🎯 What type of release?"
echo "1) Alpha (early testing)"
echo "2) Beta (feature complete, testing)"
echo "3) Release (stable)"
echo ""

while true; do
    read -p "Select release type (1-3): " RELEASE_TYPE
    case $RELEASE_TYPE in
        1)
            RELEASE_SUFFIX="-alpha"
            break
            ;;
        2)
            RELEASE_SUFFIX="-beta"
            break
            ;;
        3)
            RELEASE_SUFFIX=""
            break
            ;;
        *)
            echo "❌ Invalid selection. Please choose 1-3."
            ;;
    esac
done

# Create the full tag name
FULL_TAG="v${NEW_VERSION}${RELEASE_SUFFIX}"

echo ""
echo "📝 Summary:"
echo "   Previous tag: $LATEST_TAG"
echo "   New tag: $FULL_TAG"
echo "   Release type: $([ "$RELEASE_SUFFIX" = "" ] && echo "Release" || echo "${RELEASE_SUFFIX#-}")"
echo ""

# Final confirmation
read -p "🚀 Create and push tag '$FULL_TAG'? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted."
    exit 1
fi

# Create the tag
echo "📦 Creating tag: $FULL_TAG"
git tag -a "$FULL_TAG" -m "Release $FULL_TAG

$([ "$RELEASE_SUFFIX" = "-alpha" ] && echo "Alpha release for testing and feedback." || 
  [ "$RELEASE_SUFFIX" = "-beta" ] && echo "Beta release - feature complete, testing phase." || 
  echo "Stable release version.")"

# Push the tag
echo "📤 Pushing tag to origin..."
git push origin "$FULL_TAG"

echo ""
echo "✅ Success! Tag '$FULL_TAG' has been created and pushed."
echo "🔗 GitHub Actions will now automatically:"
echo "   • Package the addon"
echo "   • Create a GitHub release"
echo "   • Upload to CurseForge (if configured)"
echo ""
echo "🌐 Check your releases at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/releases"
echo ""
echo "🎉 Release process initiated!"
