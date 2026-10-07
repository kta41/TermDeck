# common.sh — utilidades compartidas por los scripts ck-*
# Se carga con: source "$(dirname "$(readlink -f "$0")")/lib/common.sh"
# No ejecutar directamente.

# ---- rutas y tiempos (variables de entorno para poder afinar sin editar) ----
CK_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/terminal-cockpit"
CK_STATE_FILE="$CK_CACHE_DIR/state"
CK_K_TIMEOUT="${CK_K_TIMEOUT:-5}"     # seg. máx para cualquier kubectl
CK_API_TIMEOUT="${CK_API_TIMEOUT:-4}" # seg. máx para probes de red
CK_API_EVERY="${CK_API_EVERY:-60}"    # re-check del API como mucho cada N seg
CK_ARGO_EVERY="${CK_ARGO_EVERY:-300}" # re-check de ArgoCD cada N seg

ck_have() { command -v "$1" >/dev/null 2>&1; }

# kubectl de k3s ignora ~/.kube/config si KUBECONFIG no está exportado (cae en
# /etc/rancher/k3s/k3s.yaml, solo legible por root). Lo fijamos por defecto.
if [ -z "${KUBECONFIG:-}" ] && [ -r "$HOME/.kube/config" ]; then
  KUBECONFIG="$HOME/.kube/config"
  export KUBECONFIG
fi

# kubectl SIEMPRE con timeout: si el API de k3s está caído, nada se cuelga.
ck_kubectl() { timeout "$CK_K_TIMEOUT" kubectl "$@"; }

# Ejecuta kubectl y si el timeout lo mata (124) muestra aviso en stderr.
ck_k8s_run() {
  local out rc
  out="$(ck_kubectl "$@" 2>&1)"
  rc=$?
  if [ $rc -eq 124 ]; then
    echo "API de Kubernetes no responde (timeout de ${CK_K_TIMEOUT}s)" >&2
    return 124
  fi
  printf '%s\n' "$out"
  return $rc
}

# ---- archivo de estado (lo pinta WezTerm leyendo \\wsl.localhost\...) ----
ck_now() { date +%s; }

ck_state_get() { # ck_state_get <clave> [archivo]
  local f="${2:-$CK_STATE_FILE}"
  [ -r "$f" ] || return 1
  sed -n "s/^$1=//p" "$f" | head -1
}

ck_state_set() { # ck_state_set clave valor  (reescribe el estado de forma atómica)
  local k="$1" v="$2" f="$CK_STATE_FILE" tmp
  mkdir -p "$CK_CACHE_DIR" || return 1
  tmp="$f.tmp"
  { [ -r "$f" ] && grep -v "^$k=" "$f"; printf '%s=%s\n' "$k" "$v"; } >"$tmp" 2>/dev/null
  mv "$tmp" "$f"
}

# ck_throttled <clave-timestamp> <intervalo-s> → 0 si toca ejecutar
ck_throttled() {
  local last; last="$(ck_state_get "$1")"
  [ -n "$last" ] || return 0
  [ "$(( $(ck_now) - last ))" -ge "$2" ]
}

# ---- git: helpers compartidos por ck-git y ck-ci ----
ck_git_root() { git rev-parse --show-toplevel 2>/dev/null || true; }

ck_git_url() {
  git remote get-url origin 2>/dev/null || git config --get remote.origin.url 2>/dev/null || true
}

# Convierte cualquier remote (ssh/https) en https://host/owner/repo (sin .git)
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

# github | gitlab | (exit 1 si no se reconoce al proveedor)
ck_git_provider() {
  local u; u="$(ck_git_https)" || return 1
  case "$u" in
    *github.com*) echo github ;;
    *gitlab.*) echo gitlab ;;
    *) return 1 ;;
  esac
}

# ---- colores (solo si stdout es una terminal) ----
if [ -t 1 ]; then
  CK_C_G=$'\033[32m'; CK_C_R=$'\033[31m'; CK_C_Y=$'\033[33m'
  CK_C_B=$'\033[34m'; CK_C_0=$'\033[0m'
else
  CK_C_G=''; CK_C_R=''; CK_C_Y=''; CK_C_B=''; CK_C_0=''
fi
