# shell-hook.sh — cockpit integration into bash.
# Add at the end of ~/.bashrc (WSL Debian):
#   source /mnt/c/dev/dotfiles/scripts/shell-hook.sh
# Does two cheap things after every prompt:
#   1) OSC 7: tells WezTerm the current cwd (enables the contextual palette)
#   2) refreshes cockpit state in the background (throttled internally)

# interactive shells only
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

# Do not register the hook twice when the user reloads this file.
if declare -F __ck_hook >/dev/null 2>&1; then
  return 0
fi

__ck_hook() {
  printf '\033]7;file://%s%s\033\\' "${HOSTNAME:-localhost}" "$PWD"
  local dir="${PWD##*/}"
  [ -z "$dir" ] && dir='/'
  [ "$PWD" = "$HOME" ] && dir='~'
  local command
  command="$(fc -ln -1 2>/dev/null || true)"
  command="${command#"${command%%[![:space:]]*}"}"
  local verb="${command%% *}"
  [ -z "$verb" ] && verb='shell'
  printf '\033]2;%s > %s\007' "$dir" "$verb"
  if [ -x "$HOME/.local/bin/ck" ]; then
    local ckdir="${XDG_CACHE_HOME:-$HOME/.cache}/terminal-cockpit"
    ( "$HOME/.local/bin/ck" status --quiet >/dev/null 2>&1 & )
    # pre-warm the palette context for THIS directory: WezTerm then opens the
    # palette instantly (file read) instead of spawning wsl.exe
    ( "$HOME/.local/bin/ck" palette >"$ckdir/context.tmp" 2>/dev/null && mv "$ckdir/context.tmp" "$ckdir/context" & )
  fi
}

PROMPT_COMMAND="__ck_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
