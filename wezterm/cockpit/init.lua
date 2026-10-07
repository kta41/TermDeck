-- init.lua — cockpit entry point. wezterm.lua loads it through pcall:
-- if anything in this layer fails, the base configuration keeps working.
local wezterm = require 'wezterm'
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

  return config
end

return M
