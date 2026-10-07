<div align="center">

# TermDeck 🚀
> *A high-performance terminal cockpit uniting WezTerm, Starship, and custom WSL automation.*

</div>

<p align="center">
  <img alt="Lua" src="https://img.shields.io/badge/Lua-55.4%25-blue?style=flat-square&logo=lua">
  <img alt="Shell" src="https://img.shields.io/badge/Shell-44.6%25-orange?style=flat-square&logo=gnu-bash">
  <img alt="License: OFL 1.1" src="https://img.shields.io/badge/License-OFL%201.1-lightgrey?style=flat-square">
  <img alt="Platform: Windows / WSL2" src="https://img.shields.io/badge/Platform-Windows%20%2F%20WSL2-informational?style=flat-square&logo=windows">
</p>

---

A **live** configuration repository: configs are consumed through symlinks, never copied.

```text
Windows:  %USERPROFILE%\.config\wezterm\wezterm.lua  → wezterm/wezterm.lua
          %USERPROFILE%\.config\wezterm\fonts        → wezterm/fonts
          %USERPROFILE%\.config\wezterm\cockpit      → wezterm/cockpit
WSL:      ~/.config/starship.toml                     → starship/starship.toml
          ~/.local/bin/ck*                            → scripts/ck*
```

---

## 🏛️ Architecture

```text
WezTerm (UI layer)                      Starship (prompt layer)
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

### Core Principles

* **The shell stays the shell:** The palette types plain commands into the active pane (history included). Nothing is replaced by a heavy monolithic app.
* **Nothing hangs:** Every `kubectl`/`argocd`/`curl` call is wrapped in `timeout` with asynchronous caching. The WezTerm status bar only reads a local file written by the shell—it never spawns synchronous processes, meaning a down cluster can **never** freeze your UI.
* **Context-aware gating:** Palette sections are strictly gated on real environment detection: installed tools (`ck doctor`), current repository and its provider, CI configs (`.github/workflows` / `.gitlab-ci.yml`), and ArgoCD status.
* **Zero duplication:** Git context lives cleanly in Starship; cluster health lives in the WezTerm status bar.

---

## 🎮 Usage

| Shortcut | Action |
| :--- | :--- |
| `LEADER` then `P` | Cockpit fuzzy palette (Git / Repo / K8s / Argo / CI) |
| All other shortcuts | Unchanged (tmux-style, `LEADER` + `1..9`, etc.) |

### Direct CLI (Works standalone without WezTerm)

```bash
ck doctor                      # Check what is installed in WSL
ck status [--force]            # Refresh k8s/argo state (also feeds WezTerm)
ck git info | branches | url repo|pulls|ci
ck k8s contexts|namespaces|pods|deployments|services|events [--names] [ns]
ck ci detect|runs|failed|ids|view <id>|rerun <id>|page
ck argocd detect|apps|names|get|sync|refresh|history|logs <app>
```

---

## ⚙️ Installation & Replication

1. **Set up the symlinks** shown above (Windows: `New-Item -ItemType SymbolicLink`; WSL: `ln -s`).
2. **Hook into your shell** by adding this line at the end of `~/.bashrc` (WSL Debian):
   ```bash
   source /mnt/c/dev/TermDeck/scripts/shell-hook.sh
   ```
3. **Ensure line endings (LF):** Scripts must keep **LF** endings (`.gitattributes` enforces this; note that on `/mnt/c`, CRLF breaks bash scripts).

---

## 📂 Repository Structure

* `wezterm/wezterm.lua` — Base configuration + guarded (`pcall`) cockpit loading.
* `wezterm/cockpit/` — Modular UI components: `init` (wiring), `config` (constants), `wsl` (WezTerm⇄WSL bridge), `util` (send/pickers), `status`, `palette`, and domain entries (`git`, `k8s`, `argocd`, `ci`).
* `scripts/` — The `ck` command dispatcher + specialized scripts (`ck-git`, `ck-k8s`, `ck-ci`, `ck-argocd`, `ck-status`), `shell-hook.sh`, and `lib/common.sh`.
* `starship/starship.toml` — Prompt layout with integrated `kubernetes` module.
* `wezterm/fonts/` — JetBrainsMono Nerd Font, licensed under the SIL Open Font License 1.1 (see `wezterm/fonts/OFL.txt`).

---

## 💡 Verified Environment Notes

* Tested on **WezTerm `20240203`**, WSL2 Debian, using `kubectl` bound to the `k3s` binary.
* **Graceful Degradation:** If `gh`, `glab`, or the `argocd` CLI are missing, those palette sections remain hidden automatically until the tools are installed.
* **Resilience:** If the k3s API drops, the status bar safely displays `☸ ctx · ns` with a red indicator, and K8s pickers report *"no results"* instead of locking up the terminal.
