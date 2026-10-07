-- config.lua — constantes del cockpit. Ajusta aquí; el resto de módulos no
-- debería necesitar cambios.
local M = {
  distro = 'Debian',                    -- coincide con default_domain 'WSL:Debian'
  wsl_user = 'Kta41',                   -- $USER dentro de WSL (ruta UNC del estado)
  state_rel_path = '.cache/terminal-cockpit/state', -- lo escribe `ck status`
  caps_ttl = 30,                        -- seg. que se cachea `ck doctor` en la paleta
  state_max_age = 300,                  -- seg. tras los que el status se considera viejo
  palette_key = { key = 'p', mods = 'LEADER' },     -- LEADER+P abre la paleta
}
return M
