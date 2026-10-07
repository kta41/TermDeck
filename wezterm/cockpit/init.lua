-- init.lua — punto de entrada del cockpit. wezterm.lua lo carga con pcall:
-- si algo de esta capa falla, la configuración base sigue funcionando igual.
local wezterm = require 'wezterm'
local cfg = require 'cockpit.config'
local status = require 'cockpit.status'
local palette = require 'cockpit.palette'

local M = {}

function M.setup(config)
  -- refresco periódico del status derecho (leer un archivo pequeño es barato)
  config.status_update_interval = 2000
  wezterm.on('update-right-status', status.update)

  -- paleta de acciones: LEADER+P (no colisiona con LEADER+1..9 existentes)
  table.insert(config.keys, {
    key = cfg.palette_key.key,
    mods = cfg.palette_key.mods,
    action = wezterm.action_callback(palette.open),
  })

  return config
end

return M
