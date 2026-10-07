# shell-hook.sh — cockpit integration into bash.
# Add at the end of ~/.bashrc (WSL Debian):
#   source /mnt/c/dev/dotfiles/scripts/shell-hook.sh
# Does two cheap things after every prompt:
#   1) OSC 7: tells WezTerm the current cwd (enables the contextual palette)
#   2) refreshes cockpit state in the background (throttled internally)

# interactive shells only
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

__ck_hook() {
  printf '\033]7;file://%s%s\033\\' "${HOSTNAME:-localhost}" "$PWD"
  if [ -x "$HOME/.local/bin/ck" ]; then
    ( "$HOME/.local/bin/ck" status --quiet >/dev/null 2>&1 & )
  fi
}

PROMPT_COMMAND="__ck_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
