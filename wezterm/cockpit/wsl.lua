-- wsl.lua — WezTerm (Windows) ⇄ WSL Debian bridge:
--   * run commands inside WSL (pickers, detection)
--   * read the state file written by `ck status` (cheap: no processes)
local wezterm = require 'wezterm'
local cfg = require 'cockpit.config'

local M = {}

-- Windows UNC path to the user's state file inside WSL.
function M.state_path()
  return '\\\\wsl.localhost\\' .. cfg.distro .. '\\home\\' .. cfg.wsl_user .. '\\'
    .. (cfg.state_rel_path:gsub('/', '\\'))
end

-- Reads the key=value state written by ck-status. Returns a table (empty on error).
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

-- Runs cmd with a login bash inside WSL. opts.cwd = initial Linux path.
-- Returns stdout or nil. Network-touching commands must carry `timeout`.
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

-- Same as run() but returns the list of non-empty lines (or nil).
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

-- Runs a ck subcommand using an absolute path (non-interactive shells may not
-- have ~/.local/bin on PATH). args = 'k8s pods --names'
function M.ck(args, opts)
  local cmd = 'CK="$HOME/.local/bin/ck"; '
    .. '[ -x "$CK" ] || CK="$(command -v ck 2>/dev/null)"; '
    .. '[ -n "$CK" ] && "$CK" ' .. args .. ' 2>/dev/null'
  return M.run(cmd, opts)
end

-- Does the current pane belong to the cockpit's WSL domain?
function M.pane_is_wsl(pane)
  local ok, name = pcall(function()
    return pane:get_domain_name()
  end)
  return ok and name == 'WSL:' .. cfg.distro
end

-- Pane cwd from OSC 7 (emitted by scripts/shell-hook.sh) → '/home/...' | nil
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
