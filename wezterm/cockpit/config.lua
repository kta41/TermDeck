-- config.lua — cockpit constants. Tune here; no other module should need
-- changes.
local M = {
  distro = 'Debian',                    -- matches default_domain 'WSL:Debian'
  wsl_user = 'Kta41',                   -- $USER inside WSL (UNC path for state)
  wsl_exe = 'C:\\Windows\\System32\\wsl.exe', -- absolute path (safer for spawning)
  ck_path = '/mnt/c/dev/dotfiles/scripts/ck', -- called without a shell: no quotes/spaces allowed
  zellij_bin = '/home/Kta41/.local/bin/zellij', -- session layer (Zellij)
  state_rel_path = '.cache/terminal-cockpit/state', -- written by `ck status`
  context_rel_path = '.cache/terminal-cockpit/context', -- pre-warmed by the shell hook
  caps_ttl = 30,                        -- seconds `ck doctor` is cached in the palette
  -- Staleness window for the right status. Generous on purpose: WezTerm runs on
  -- Windows and `ck status` runs in WSL, and the two clocks can drift apart
  -- (a known WSL2 issue after sleep/distro restart). A small window here would
  -- make the status disappear forever when that happens.
  state_max_age = 21600,                -- seconds (6 h) before status is considered stale
  palette_key = { key = 'p', mods = 'LEADER' },     -- LEADER+P opens the palette
  -- Background of the right-status "chip" (context · ns · dot). Slightly
  -- darker than the titlebar so it reads as a chip; tune it here.
  status_bg = '#181825',
}
return M
