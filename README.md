# dotfiles — terminal cockpit (WezTerm + Starship)

Repositorio de configuración **en vivo**: la config se consume por symlink, no
se copia.

```
Windows:  C:\Users\eltom\.config\wezterm\wezterm.lua  → wezterm/wezterm.lua
          C:\Users\eltom\.config\wezterm\fonts        → wezterm/fonts
          C:\Users\eltom\.config\wezterm\cockpit      → wezterm/cockpit   (nuevo)
WSL:      ~/.config/starship.toml                     → starship/starship.toml
          ~/.local/bin/ck*                            → scripts/ck*        (nuevo)
```

## Arquitectura

```
WezTerm (UI)                          Starship (prompt)
  LEADER+P  paleta de acciones          git branch/status + ☸ contexto/ns
  status derecho (lectura de archivo)   (solo lee kubeconfig: sin API calls)
        │ SendString / InputSelector
        ▼
  scripts/ck*  (bash en WSL, con timeout y caché — también usables a mano)
        ├── git        → git CLI
        ├── k8s        → kubectl (k3s)
        ├── ci         → gh / glab si están; API pública (curl) para repos
        │                públicos de GitHub; detección por archivos del repo
        ├── argocd     → argocd CLI con sesión, o solo-lectura vía kubectl
        └── status     → escribe ~/.cache/terminal-cockpit/state
                            ▲
  scripts/shell-hook.sh (bash): OSC 7 (cwd) + refresh del estado por prompt
```

Principios:

- **El shell sigue siendo el shell.** La paleta escribe comandos normales en el
  pane (historial incluido). No hay app que reemplace nada.
- **Nada cuelga.** Todo `kubectl`/`argocd`/`curl` lleva `timeout` y caché.
  El status de WezTerm **solo lee un archivo** que escribe el shell: nunca
  lanza procesos (el API caído no puede congelar la UI).
- **Solo aparece lo que existe.** La paleta oculta secciones según detección
  real: herramientas instaladas (`ck doctor`), repo actual y su proveedor,
  CI del repo (`.github/workflows` / `.gitlab-ci.yml`), ArgoCD (CLI + sesión o
  CRD en el clúster).
- **Sin duplicar.** Git vive en Starship; la salud del clúster vive en el
  status de WezTerm.

## Uso

| Atajo | Acción |
|---|---|
| `LEADER+P` | paleta del cockpit (Git / Repo / K8s / Argo / CI) |
| resto de atajos | sin cambios (tmux-style, LEADER+1..9, etc.) |

CLI directo (funciona igual sin WezTerm):

```
ck doctor                     qué hay instalado en WSL
ck status [--force]           estado k8s/argo (y lo pinta WezTerm)
ck git info | branches | url repo|pulls|ci
ck k8s contexts|namespaces|pods|deployments|services|events [--names] [ns]
ck ci detect|runs|failed|ids|view <id>|rerun <id>|page
ck argocd detect|apps|names|get|sync|refresh|history|logs <app>
```

## Instalación (por si se replica en otra máquina)

1. Symlinks de arriba (Windows: `New-Item -ItemType SymbolicLink`; WSL: `ln -s`).
2. Al final de `~/.bashrc` (WSL Debian):
   `source /mnt/c/dev/dotfiles/scripts/shell-hook.sh`
3. Los scripts deben conservar **LF** (`.gitattributes` lo garantiza; en /mnt/c
   el CRLF rompe bash).

## Ficheros

- `wezterm/wezterm.lua` — config base + carga protegida (`pcall`) del cockpit.
- `wezterm/cockpit/` — `init` (cableado), `config` (constantes), `wsl` (puente
  WezTerm⇄WSL), `util` (send/selectores), `status`, `palette`,
  `git|k8s|argocd|ci` (entradas de paleta).
- `scripts/` — `ck` (dispatcher) + `ck-git|ck-k8s|ck-ci|ck-argocd|ck-status`,
  `shell-hook.sh`, `lib/common.sh`.
- `starship/starship.toml` — prompt (+ módulo `kubernetes`).

## Notas de entorno verificadas

- WezTerm `20240203`, WSL2 Debian (default domain), kubectl = binario de k3s.
- `gh`, `glab` y `argocd` no están instalados: esas secciones se ocultan hasta
  que existan (instala el CLI y la paleta las mostrará automáticamente).
- Si el API de k3s está parado, el status muestra `☸ ctx · ns ●` en rojo y los
  selectores de K8s avisan "sin resultados" en lugar de colgar.
