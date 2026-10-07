-- wsl.lua — puente WezTerm (Windows) ⇄ WSL Debian:
--   * ejecutar comandos dentro de WSL (listados para selectores, detección)
--   * leer el archivo de estado que escribe `ck status` (barato: sin procesos)
local wezterm = require 'wezterm'
local cfg = require 'cockpit.config'

local M = {}

-- Ruta UNC de Windows hacia el archivo de estado del usuario en WSL.
function M.state_path()
  return '\\\\wsl.localhost\\' .. cfg.distro .. '\\home\\' .. cfg.wsl_user .. '\\'
    .. (cfg.state_rel_path:gsub('/', '\\'))
end

-- Lee el estado key=value escrito por ck-status. Devuelve tabla (vacía si error).
function M.read_state()
  local ok, res = pcall(function()
    local f = io.open(M.state_path(), 'r')
    if not f then
      return {}
    end
    local t = {}
    for line in f:lines() do
      local k, v = line:match '^(%w+)=(.*)$'
      if k then
        t[k] = v
      end
    end
    f:close()
    return t
  end)
  if ok then
    return res
  end
  return {}
end

-- Ejecuta cmd con bash de login dentro de WSL. opts.cwd = ruta Linux inicial.
-- Devuelve stdout o nil. Los comandos que tocan la red deben llevar `timeout`.
function M.run(cmd, opts)
  opts = opts or {}
  local args = { 'wsl.exe', '-d', cfg.distro }
  if opts.cwd then
    table.insert(args, '--cd')
    table.insert(args, opts.cwd)
  end
  table.insert(args, '--')
  table.insert(args, 'bash')
  table.insert(args, '-lc')
  table.insert(args, cmd)
  local ok, out = wezterm.run_child_process(args)
  if ok then
    return out
  end
  return nil
end

-- Igual que run() pero devuelve la lista de líneas no vacías (o nil).
function M.lines(cmd, opts)
  local out = M.run(cmd, opts)
  if not out then
    return nil
  end
  local res = {}
  for line in out:gmatch '[^\r\n]+' do
    table.insert(res, line)
  end
  return res
end

-- Ejecuta un subcomando del dispatcher ck usando ruta absoluta (en shells no
-- interactivos ~/.local/bin puede no estar en PATH). args = 'k8s pods --names'
function M.ck(args, opts)
  local cmd = 'CK="$HOME/.local/bin/ck"; '
    .. '[ -x "$CK" ] || CK="$(command -v ck 2>/dev/null)"; '
    .. '[ -n "$CK" ] && "$CK" ' .. args .. ' 2>/dev/null'
  return M.run(cmd, opts)
end

-- ¿El pane actual pertenece al dominio WSL del cockpit?
function M.pane_is_wsl(pane)
  local ok, name = pcall(function()
    return pane:get_domain_name()
  end)
  return ok and name == 'WSL:' .. cfg.distro
end

-- cwd del pane según OSC 7 (lo emite scripts/shell-hook.sh) → '/home/...' | nil
function M.pane_cwd(pane)
  local ok, url = pcall(function()
    return pane:get_current_working_dir()
  end)
  if not ok or url == nil then
    return nil
  end
  local s = tostring(url)
  s = s:gsub('^wsl://[^/]+', ''):gsub('^file://[^/]*', '')
  if s:sub(1, 1) == '/' then
    return s
  end
  return nil
end

return M
