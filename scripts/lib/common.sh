# common.sh — shared helpers for the ck-* scripts.
# Load with: source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
# Do not execute directly.

# ---- paths and timings (env vars, so you can tune without editing) ----
CK_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/terminal-cockpit"
CK_STATE_FILE="$CK_CACHE_DIR/state"
CK_K_TIMEOUT="${CK_K_TIMEOUT:-5}"     # max seconds for any kubectl call
CK_API_TIMEOUT="${CK_API_TIMEOUT:-4}" # max seconds for network probes
CK_API_EVERY="${CK_API_EVERY:-60}"    # re-check the API at most every N s
CK_ARGO_EVERY="${CK_ARGO_EVERY:-300}" # re-check ArgoCD every N s

ck_have() { command -v "$1" >/dev/null 2>&1; }

# The k3s kubectl ignores ~/.kube/config unless KUBECONFIG is exported (it
# falls back to /etc/rancher/k3s/k3s.yaml, root-only). Set a sane default.
if [ -z "${KUBECONFIG:-}" ] && [ -r "$HOME/.kube/config" ]; then
  KUBECONFIG="$HOME/.kube/config"
  export KUBECONFIG
fi

# kubectl ALWAYS with a timeout: if the k3s API is down, nothing hangs.
ck_kubectl() { timeout "$CK_K_TIMEOUT" kubectl "$@"; }

# Runs kubectl; if the timeout kills it (124), print a warning to stderr.
ck_k8s_run() {
  local out rc
  out="$(ck_kubectl "$@" 2>&1)"
  rc=$?
  if [ $rc -eq 124 ]; then
    echo "Kubernetes API not responding (${CK_K_TIMEOUT}s timeout)" >&2
    return 124
  fi
  printf '%s\n' "$out"
  return $rc
}

# ---- state file (WezTerm renders it reading \\wsl.localhost\...) ----
ck_now() { date +%s; }

ck_state_get() { # ck_state_get <key> [file]
  local f="${2:-$CK_STATE_FILE}"
  [ -r "$f" ] || return 1
  sed -n "s/^$1=//p" "$f" | head -1
}

ck_state_set() { # ck_state_set key value  (atomic state rewrite)
  local k="$1" v="$2" f="$CK_STATE_FILE" tmp
  mkdir -p "$CK_CACHE_DIR" || return 1
  tmp="$f.tmp"
  { [ -r "$f" ] && grep -v "^$k=" "$f"; printf '%s=%s\n' "$k" "$v"; } >"$tmp" 2>/dev/null
  mv "$tmp" "$f"
}

# ck_throttled <timestamp-key> <interval-s> → 0 if it is time to run
ck_throttled() {
  local last; last="$(ck_state_get "$1")"
  [ -n "$last" ] || return 0
  [ "$(( $(ck_now) - last ))" -ge "$2" ]
}

# ---- git: helpers shared by ck-git and ck-ci ----
ck_git_root() { git rev-parse --show-toplevel 2>/dev/null || true; }

ck_git_url() {
  git remote get-url origin 2>/dev/null || git config --get remote.origin.url 2>/dev/null || true
}

# Turns any remote (ssh/https) into https://host/owner/repo (no .git)
ck_git_https() {
  local u host path
  u="$(ck_git_url)"; [ -n "$u" ] || return 1
  u="${u%.git}"
  case "$u" in
    ssh://git@*) u="https://${u#ssh://git@}" ;;
    git@*)
      host="${u#git@}"; host="${host%%:*}"
      path="${u#*:}"
      u="https://$host/$path"
      ;;
    http*) : ;;
    *) return 1 ;;
  esac
  printf '%s' "$u"
}

# github | gitlab | (exit 1 when the provider is not recognized)
ck_git_provider() {
  local u; u="$(ck_git_https)" || return 1
  case "$u" in
    *github.com*) echo github ;;
    *gitlab.*) echo gitlab ;;
    *) return 1 ;;
  esac
}

# ---- colors (only when stdout is a terminal) ----
if [ -t 1 ]; then
  CK_C_G=$'\033[32m'; CK_C_R=$'\033[31m'; CK_C_Y=$'\033[33m'
  CK_C_B=$'\033[34m'; CK_C_0=$'\033[0m'
else
  CK_C_G=''; CK_C_R=''; CK_C_Y=''; CK_C_B=''; CK_C_0=''
fi
