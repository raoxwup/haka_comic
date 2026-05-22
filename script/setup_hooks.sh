#!/bin/bash
# Optional: install a post-merge git hook that auto-downloads dictionaries
# after pulling new changes. Run once: bash script/setup_hooks.sh

HOOK_PATH=".git/hooks/post-merge"
SCRIPT='dart run script/download_opencc_dict.dart'

if [ -f "$HOOK_PATH" ]; then
  if grep -qF "$SCRIPT" "$HOOK_PATH"; then
    echo "Hook already configured."
    exit 0
  fi
  echo "" >> "$HOOK_PATH"
  echo "$SCRIPT" >> "$HOOK_PATH"
  echo "Appended to existing post-merge hook."
else
  echo "#!/bin/bash" > "$HOOK_PATH"
  echo "$SCRIPT" >> "$HOOK_PATH"
  chmod +x "$HOOK_PATH"
  echo "Created post-merge hook."
fi
