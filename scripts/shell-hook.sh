# shell-hook.sh — integración del cockpit en bash.
# Añade al final de ~/.bashrc (WSL Debian):
#   source /mnt/c/dev/dotfiles/scripts/shell-hook.sh
# Hace dos cosas ligeras tras cada prompt:
#   1) OSC 7: informa a WezTerm del cwd actual (habilita la paleta contextual)
#   2) refresca el estado del cockpit en background (con throttle interno)

# solo en shells interactivos
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

__ck_hook() {
  printf '\033]7;file://%s%s\033\\' "${HOSTNAME:-localhost}" "$PWD"
  if [ -x "$HOME/.local/bin/ck" ]; then
    ( "$HOME/.local/bin/ck" status --quiet >/dev/null 2>&1 & )
  fi
}

PROMPT_COMMAND="__ck_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
