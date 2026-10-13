-- init.lua — cockpit entry point. wezterm.lua loads it through pcall:
-- if anything in this layer fails, the base configuration keeps working.
local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = require 'cockpit.config'
local status = require 'cockpit.status'
local palette = require 'cockpit.palette'
local help = require 'cockpit.help'

local M = {}

function M.setup(config)
  -- periodic refresh of the right status (reading a small file is cheap)
  config.status_update_interval = 2000
  wezterm.on('update-right-status', status.update)

  -- Keep the leader binding for tmux-style use and provide a direct shortcut.
  -- Direct CTRL+P must be handled by WezTerm before Zellij sees it.
  table.insert(config.keys, {
    key = cfg.palette_key.key,
    mods = cfg.palette_key.mods,
    action = wezterm.action_callback(palette.open),
  })
  table.insert(config.keys, {
    key = 'p',
    mods = 'CTRL',
    action = wezterm.action_callback(palette.open),
  })

  -- alternative trigger without the leader: handy and a diagnostic aid
  -- (if F9 opens the palette but LEADER+P does not, the issue is key timing:
  -- press Ctrl+A, RELEASE, then press p within the 1s leader timeout)
  table.insert(config.keys, {
    key = 'F9',
    action = wezterm.action_callback(palette.open),
  })

  -- CTRL+H: native WezTerm help overlay. It does not spawn WSL, so it cannot
  -- disappear because a script or working directory failed to resolve.
  table.insert(config.keys, {
    key = 'h',
    mods = 'CTRL',
    action = wezterm.action_callback(help.open),
  })

  return config
end

return M
