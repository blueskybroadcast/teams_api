# Teams API Automated Versioning

This document describes the automated versioning system implemented for the Teams API engine.

## Overview

The Teams API engine uses semantic versioning (X.Y.Z):

- **X**: Major version - Breaking changes
- **Y**: Minor version - New features, backwards compatible
- **Z**: Patch version - Bug fixes, backwards compatible

Version numbers are stored in `lib/teams_api/version.rb` and automatically updated using GitHub Actions workflows.

## Automated Workflow

The versioning process follows these steps:

1. When code is pushed to the main branch, a GitHub Action automatically:
   - Determines the appropriate version increment
   - Creates a branch with the updated version
   - Opens a Pull Request for review

2. After PR approval and merge, another workflow:
   - Creates a git tag for the version
   - Generates a GitHub Release with release notes

## Controlling Version Increments

Control which version segment is incremented by using these tags in your commit messages:

| Commit Message Tag | Example | Result |
|-------------------|---------|--------|
| `[major]` | `[major] Redesign API endpoints` | 1.0.0 → 2.0.0 |
| `[minor]` | `[minor] Add team filtering feature` | 1.0.0 → 1.1.0 |
| (none) | `Fix authentication bug` | 1.0.0 → 1.0.1 |
| `[skip-version]` | `Update README [skip-version]` | No version change |

## Examples

```bash
# Triggers patch version bump (0.1.0 → 0.1.1)
git commit -m "Fix bug in authentication module"

# Triggers minor version bump (0.1.1 → 0.2.0)
git commit -m "[minor] Add new reporting features"

# Triggers major version bump (0.2.0 → 1.0.0)
git commit -m "[major] Complete API redesign"

# Skips version bump
git commit -m "Update documentation [skip-version]"
```

## Benefits

- **Consistency**: Ensures proper semantic versioning practice
- **Automation**: Eliminates manual version updates
- **Transparency**: Makes version increments visible through PRs
- **Release Notes**: Automatically generates GitHub releases
- **History**: Maintains clear version history with tags

## Implementation Details

This system uses GitHub Actions workflows:
- `.github/workflows/version-bump.yml` - Creates version PRs
- `.github/workflows/create-release.yml` - Creates tags and releases

The automation works with Rails engines following standard Gem versioning practices.