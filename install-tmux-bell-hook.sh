#!/bin/bash
# Install Claude Code notification hook that sends a terminal bell
# when Claude is idle or needs attention, so tmux highlights the window tab.
#
# Installs to ~/.claude/settings.json (user-level, all projects).

set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

HOOK_JSON='{
    "Notification": [
      {
        "matcher": "idle_prompt|permission_prompt|elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "command": "printf '"'"'\\a'"'"'"
          }
        ]
      }
    ]
  }'

# Check if already installed
if [ -f "$SETTINGS_FILE" ] && jq -e '.hooks.Notification' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "Hook already exists in $SETTINGS_FILE — nothing to do."
  exit 0
fi

echo "This will add a Notification hook to $SETTINGS_FILE"
echo "The hook sends a terminal bell when Claude is idle or needs attention."
echo ""
read -rp "Proceed? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ -f "$SETTINGS_FILE" ]; then
  jq --argjson hooks "$HOOK_JSON" '.hooks = (.hooks // {}) + $hooks' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
  mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
else
  jq -n --argjson hooks "$HOOK_JSON" '{ hooks: $hooks }' > "$SETTINGS_FILE"
fi

echo ""
echo "Installed hook to $SETTINGS_FILE"

cat <<'GUIDE'

=== tmux setup ===

Add these lines to your tmux config (~/.tmux.conf or ~/.config/tmux/tmux.conf):

  set -g monitor-bell on
  set -g bell-action any
  setw -g window-status-bell-style reverse

Then reload tmux:

  tmux source-file ~/.config/tmux/tmux.conf

How it works:
  - When Claude goes idle or asks for permission, the hook sends a
    terminal bell character (\a).
  - tmux detects the bell and highlights the window tab (reverse style)
    so you can spot which window needs attention.
  - The highlight only shows on *background* windows, not the one
    you're currently viewing.

GUIDE
