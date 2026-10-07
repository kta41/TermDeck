# TermDeck — terminal cockpit (WezTerm + Starship)

A **live** configuration repository: configs are consumed through symlinks,
never copied.

```
Windows:  %USERPROFILE%\.config\wezterm\wezterm.lua  → wezterm/wezterm.lua
          %USERPROFILE%\.config\wezterm\fonts        → wezterm/fonts
          %USERPROFILE%\.config\wezterm\cockpit      → wezterm/cockpit
WSL:      ~/.config/starship.toml                     → starship/starship.toml
          ~/.local/bin/ck*                            → scripts/ck*
```

## Architecture

```
WezTerm (UI layer)                     Starship (prompt layer)
  LEADER+P  action palette               git branch/status + ☸ k8s context/ns
  right status bar (file read only)      (kubeconfig only: no API calls)
        │ SendString / InputSelector
        ▼
  scripts/ck*  (bash inside WSL, timeout-guarded and cached — also
               usable directly from any shell)
        ├── git        → git CLI
        ├── k8s        → kubectl (k3s)
        ├── ci         → gh / glab when installed; public API (curl) for
        │                public GitHub repos; detected from repo files
        ├── argocd     → argocd CLI with a session, or read-only kubectl
        └── status     → writes ~/.cache/terminal-cockpit/state
                            ▲
  scripts/shell-hook.sh (bash): OSC 7 (cwd) + per-prompt status refresh
```

Principles:

- **The shell stays the shell.** The palette types plain commands into the
  active pane (history included). Nothing is replaced by an app.
- **Nothing hangs.** Every `kubectl`/`argocd`/`curl` call is wrapped in
  `timeout` with caching. The WezTerm status bar only reads a file written
  by the shell — it never spawns processes, so a down cluster can never
  freeze the UI.
- **Only what exists is shown.** Palette sections are gated on real
  detection: installed tools (`ck doctor`), current repo and its provider,
  repo CI config (`.github/workflows` / `.gitlab-ci.yml`), ArgoCD (CLI
  session or in-cluster CRD).
- **No duplication.** Git context lives in Starship; cluster health lives
  in the WezTerm status bar.

## Usage

| Shortcut | Action |
|---|---|
| `LEADER` then `P` | cockpit palette (Git / Repo / K8s / Argo / CI) |
| all other shortcuts | unchanged (tmux-style, LEADER+1..9, ...) |

Direct CLI (works without WezTerm too):

```
ck doctor                     what is installed in WSL
ck status [--force]           k8s/argo state (also feeds WezTerm)
ck git info | branches | url repo|pulls|ci
ck k8s contexts|namespaces|pods|deployments|services|events [--names] [ns]
ck ci detect|runs|failed|ids|view <id>|rerun <id>|page
ck argocd detect|apps|names|get|sync|refresh|history|logs <app>
```

## Install (to replicate on another machine)

1. The symlinks shown above (Windows: `New-Item -ItemType SymbolicLink`;
   WSL: `ln -s`).
2. At the end of `~/.bashrc` (WSL Debian):
   `source /mnt/c/dev/dotfiles/scripts/shell-hook.sh`
3. Scripts must keep **LF** endings (`.gitattributes` enforces this; on
   /mnt/c, CRLF breaks bash).

## Files

- `wezterm/wezterm.lua` — base config + guarded (`pcall`) cockpit loading.
- `wezterm/cockpit/` — `init` (wiring), `config` (constants), `wsl`
  (WezTerm⇄WSL bridge), `util` (send/pickers), `status`, `palette`,
  `git|k8s|argocd|ci` (palette entries).
- `scripts/` — `ck` (dispatcher) + `ck-git|ck-k8s|ck-ci|ck-argocd|ck-status`,
  `shell-hook.sh`, `lib/common.sh`.
- `starship/starship.toml` — prompt (+ `kubernetes` module).
- `wezterm/fonts/` — JetBrainsMono Nerd Font, licensed under the SIL Open
  Font License 1.1 (see `wezterm/fonts/OFL.txt`).

## Verified environment notes

- WezTerm `20240203`, WSL2 Debian (default domain), kubectl = the k3s binary.
- `gh`, `glab` and the `argocd` CLI are not installed: those palette
  sections stay hidden until they exist (install the CLI and the palette
  will pick them up automatically).
- If the k3s API is down, the status bar shows `☸ ctx · ns` with a red dot
  and the K8s pickers report "no results" instead of hanging.
