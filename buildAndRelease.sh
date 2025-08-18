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

# Check if we're on the main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "❌ Error: Can only create releases from the 'main' branch"
    echo "   Current branch: $CURRENT_BRANCH"
    echo "   Please switch to main branch first: git checkout main"
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

# Check if this is a major version change (breaking changes)
IS_MAJOR_BUMP=false
if [[ $VERSION_TYPE == "3" ]] || ([[ $VERSION_TYPE == "4" ]] && [[ ${NEW_VERSION%%.*} -gt $MAJOR ]]); then
    IS_MAJOR_BUMP=true
fi

# Handle data version bump for breaking changes
if [[ $IS_MAJOR_BUMP == true ]]; then
    echo ""
    echo "🔄 Major version detected - checking data version..."
    
    # Get current data version from Core.lua
    CORE_FILE="Core.lua"
    if [[ ! -f "$CORE_FILE" ]]; then
        echo "❌ Error: Core.lua not found in current directory"
        exit 1
    fi
    
    CURRENT_DATA_VERSION=$(grep -o 'CURRENT_DATA_VERSION = [0-9]\+' "$CORE_FILE" | grep -o '[0-9]\+')
    if [[ -z "$CURRENT_DATA_VERSION" ]]; then
        echo "❌ Error: Could not find CURRENT_DATA_VERSION in Core.lua"
        exit 1
    fi
    
    NEW_DATA_VERSION=$((CURRENT_DATA_VERSION + 1))
    
    echo "📊 Current data version: $CURRENT_DATA_VERSION"
    echo "📈 New data version: $NEW_DATA_VERSION"
    echo ""
    echo "⚠️  This will cause a data reset for users upgrading from older versions!"
    echo "   Users will see a migration notice and their stats will be reset."
    echo ""
    
    read -p "🔄 Bump data version to $NEW_DATA_VERSION? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Update the data version in Core.lua
        echo "📝 Updating CURRENT_DATA_VERSION in Core.lua..."
        
        # Use sed to replace the data version line
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS version
            sed -i '' "s/local CURRENT_DATA_VERSION = [0-9]\+/local CURRENT_DATA_VERSION = $NEW_DATA_VERSION/" "$CORE_FILE"
        else
            # Linux version
            sed -i "s/local CURRENT_DATA_VERSION = [0-9]\+/local CURRENT_DATA_VERSION = $NEW_DATA_VERSION/" "$CORE_FILE"
        fi
        
        # Also add the new version to the breakingVersions array
        echo "📝 Adding version $NEW_DATA_VERSION to breakingVersions array..."
        
        # Find the breakingVersions array and add the new version
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS version - add the new version before the closing brace of breakingVersions
            sed -i '' "/local breakingVersions = {/,/}/ {
                /}/ i\\
    $NEW_DATA_VERSION, -- Breaking change for release v$NEW_VERSION
            }" "$CORE_FILE"
        else
            # Linux version
            sed -i "/local breakingVersions = {/,/}/ {
                /}/ i\\    $NEW_DATA_VERSION, -- Breaking change for release v$NEW_VERSION
            }" "$CORE_FILE"
        fi
        
        # Verify the data version change
        NEW_VERSION_CHECK=$(grep -o 'CURRENT_DATA_VERSION = [0-9]\+' "$CORE_FILE" | grep -o '[0-9]\+')
        
        # Verify the breaking version was added
        BREAKING_VERSION_CHECK=$(grep -c "^[[:space:]]*$NEW_DATA_VERSION, -- Breaking change" "$CORE_FILE" || true)
        
        if [[ "$NEW_VERSION_CHECK" == "$NEW_DATA_VERSION" ]] && [[ "$BREAKING_VERSION_CHECK" == "1" ]]; then
            echo "✅ Data version updated successfully: $CURRENT_DATA_VERSION → $NEW_DATA_VERSION"
            echo "✅ Added version $NEW_DATA_VERSION to breakingVersions array"
            
            # Stage the change for git
            git add "$CORE_FILE"
            echo "📦 Staged Core.lua for commit"
        else
            echo "❌ Error: Failed to update data version or breakingVersions in Core.lua"
            echo "   Data version check: expected $NEW_DATA_VERSION, got $NEW_VERSION_CHECK"
            echo "   Breaking version check: found $BREAKING_VERSION_CHECK entries"
            exit 1
        fi
    else
        echo "⏭️  Skipping data version bump"
    fi
fi

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
if [[ $IS_MAJOR_BUMP == true ]] && [[ $REPLY =~ ^[Yy]$ ]] && [[ -n "$NEW_DATA_VERSION" ]]; then
    echo "   Data version: $CURRENT_DATA_VERSION → $NEW_DATA_VERSION (⚠️  breaking change)"
fi
echo ""

# Final confirmation
read -p "🚀 Create and push tag '$FULL_TAG'? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted."
    exit 1
fi

# Double-check we're still on main branch before proceeding
CURRENT_BRANCH_CHECK=$(git branch --show-current)
if [[ "$CURRENT_BRANCH_CHECK" != "main" ]]; then
    echo "❌ Error: Branch changed during script execution!"
    echo "   Current branch: $CURRENT_BRANCH_CHECK"
    echo "   Releases can only be created from the 'main' branch"
    exit 1
fi

# Commit data version change if it was made
if [[ $IS_MAJOR_BUMP == true ]] && [[ -n "$NEW_DATA_VERSION" ]]; then
    # Check if Core.lua was actually staged (meaning data version was updated)
    if git diff --staged --name-only | grep -q "Core.lua"; then
        echo "💾 Committing data version bump..."
        git commit -m "Bump data version to $NEW_DATA_VERSION for v$NEW_VERSION

- Updated CURRENT_DATA_VERSION to $NEW_DATA_VERSION
- Added version $NEW_DATA_VERSION to breakingVersions array

This is a breaking change that will reset user data to ensure
compatibility with new features and data structures."
        echo "✅ Data version change committed"
    fi
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

# Additional info for major releases with data version bumps
if [[ $IS_MAJOR_BUMP == true ]] && [[ -n "$NEW_DATA_VERSION" ]]; then
    echo "⚠️  Important: This major release includes a data version bump!"
    echo "   • User data will be reset when they upgrade"
    echo "   • A migration notice will be shown to users"
    echo "   • Make sure release notes mention breaking changes"
    echo ""
fi

echo "🎉 Release process initiated!"
