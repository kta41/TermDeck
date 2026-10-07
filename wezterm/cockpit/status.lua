-- status.lua — right status bar: ☸ context·namespace + API state + argo.
-- It only READS the state file written by `ck status` from the shell hook:
-- no processes are ever spawned here (a down API cannot freeze the UI).
local wezterm = require 'wezterm'
local cfg = require 'cockpit.config'
local wsl = require 'cockpit.wsl'

local M = {}

local C = {
  blue = '#89b4fa', grey = '#9399b2', dim = '#6c7086',
  green = '#a6e3a1', red = '#f38ba8', yellow = '#f9e2af',
}

local function add(segs, color, text)
  table.insert(segs, { Foreground = { Color = color } })
  table.insert(segs, { Text = text })
end

function M.update(window, pane)
  pcall(function()
    if not wsl.pane_is_wsl(pane) then
      window:set_right_status('')
      return
    end
    local s = wsl.read_state()
    local updated = tonumber(s.updated or '') or 0
    local segs = {}
    if updated == 0 or (os.time() - updated) > cfg.state_max_age then
      add(segs, C.dim, ' cockpit · no data ')
    elseif s.k8s_state and s.k8s_state ~= 'none' then
      add(segs, C.blue, '☸ ' .. ((s.k8s_context ~= '' and s.k8s_context) or '?'))
      if s.k8s_namespace and s.k8s_namespace ~= '' then
        add(segs, C.grey, ' · ' .. s.k8s_namespace)
      end
      if s.k8s_state == 'ok' then
        add(segs, C.green, ' ●')
      elseif s.k8s_state == 'down' then
        add(segs, C.red, ' ●')
      else
        add(segs, C.yellow, ' ○')
      end
      if s.argocd == 'ready' then
        add(segs, C.green, '  ⎈ argo')
      end
    end
    window:set_right_status(wezterm.format(segs))
  end)
end

return M
