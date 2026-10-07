-- wsl.lua — WezTerm (Windows) ⇄ WSL Debian bridge.
-- IMPORTANT (verified on this machine, WezTerm 20240203):
--   * wezterm.run_child_process cannot spawn wsl.exe here (silently ok=false)
--   * io.popen DOES work, but cmd.exe mangles any payload containing quotes
-- Solution: io.popen + QUOTE-FREE command lines — the repo's ck script is
-- invoked directly with plain space-separated arguments. Never pass quotes,
-- parentheses or shell syntax inside `args`; put that logic inside the ck
-- scripts themselves (they run under a real bash).
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
      -- NOTE: %w in Lua does NOT include '_' (unlike regex \w) — keys such as
      -- k8s_state or api_checked need the explicit [%w_] class or they are
      -- silently skipped.
      local k, v = line:match '^([%w_]+)=(.*)$'
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

-- Runs a ck subcommand inside WSL. args = 'k8s pods --names' (quote-free!).
-- opts.cwd = initial Linux path (must not contain spaces).
-- Returns stdout (string, possibly empty) or nil when spawning failed.
function M.ck(args, opts)
  local s = '"' .. cfg.wsl_exe .. '" -d ' .. cfg.distro
  if opts and opts.cwd then
    s = s .. ' --cd ' .. opts.cwd
  end
  s = s .. ' -- ' .. cfg.ck_path .. ' ' .. args .. ' 2>/dev/null'
  local okf, f = pcall(io.popen, s)
  if not okf or not f then
    return nil
  end
  local out = f:read '*a'
  pcall(function()
    f:close()
  end)
  return out
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
