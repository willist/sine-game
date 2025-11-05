# Automated Releases

## Setup

Add these secrets to GitHub repository settings → Secrets and variables → Actions:

- `BUTLER_API_KEY` - Get from https://itch.io/user/settings/api-keys
- `ITCH_USER` - Your itch.io username
- `ITCH_GAME` - Your game's project name on itch.io

## Publishing

Use conventional commits, then merge to main:
```bash
git commit -m "feat: add wave translation controls"
git commit -m "fix: resolve wave boundary bug"
```

Automatically:
1. Analyzes commits to determine version bump (patch/minor/major)
2. Updates version in `project.godot`
3. Generates changelog and release notes
4. Creates GitHub release
5. Builds and publishes to itch.io (Web)
