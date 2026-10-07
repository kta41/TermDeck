-- config.lua — cockpit constants. Tune here; no other module should need
-- changes.
local M = {
  distro = 'Debian',                    -- matches default_domain 'WSL:Debian'
  wsl_user = 'Kta41',                   -- $USER inside WSL (UNC path for state)
  state_rel_path = '.cache/terminal-cockpit/state', -- written by `ck status`
  caps_ttl = 30,                        -- seconds `ck doctor` is cached in the palette
  state_max_age = 300,                  -- seconds before status is considered stale
  palette_key = { key = 'p', mods = 'LEADER' },     -- LEADER+P opens the palette
}
return M
