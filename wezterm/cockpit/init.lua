-- init.lua — cockpit entry point. wezterm.lua loads it through pcall:
-- if anything in this layer fails, the base configuration keeps working.
local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = require 'cockpit.config'
local status = require 'cockpit.status'
local palette = require 'cockpit.palette'

local M = {}

function M.setup(config)
  -- periodic refresh of the right status (reading a small file is cheap)
  config.status_update_interval = 2000
  wezterm.on('update-right-status', status.update)

  -- action palette: LEADER+P (does not clash with the existing LEADER+1..9)
  table.insert(config.keys, {
    key = cfg.palette_key.key,
    mods = cfg.palette_key.mods,
    action = wezterm.action_callback(palette.open),
  })

  -- alternative trigger without the leader: handy and a diagnostic aid
  -- (if F9 opens the palette but LEADER+P does not, the issue is key timing:
  -- press Ctrl+A, RELEASE, then press p within the 1s leader timeout)
  table.insert(config.keys, {
    key = 'F9',
    action = wezterm.action_callback(palette.open),
  })

  -- CTRL+H: static keyboard cheat sheet in its own tab.
  -- `ck helpscreen` prints HELP.txt and waits for ANY key (Esc included);
  -- when it exits, the tab closes by itself. All argv tokens are
  -- quote-free on purpose (this build mangles quoted spawn arguments).
  table.insert(config.keys, {
    key = 'h',
    mods = 'CTRL',
    action = act.SpawnCommandInNewTab {
      args = { cfg.wsl_exe, '-d', cfg.distro, '--', cfg.ck_path, 'helpscreen' },
    },
  })

  return config
end

return M
