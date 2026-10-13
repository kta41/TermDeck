local runtime = require 'cockpit.runtime'

local M = {}

function M.enabled()
  return runtime.read('focus.state').enabled == '1'
end

function M.set(window, enabled)
  local ok, err = runtime.write('focus.state', { enabled = enabled and 1 or 0 })
  if not ok then
    window:toast_notification('cockpit', 'focus mode: no se pudo guardar el estado: ' .. tostring(err), nil, 4000)
    return
  end
  window:toast_notification('cockpit', enabled and 'focus mode activado' or 'focus mode desactivado', nil, 2500)
  window:set_right_status('')
  window:perform_action(require('wezterm').action.ReloadConfiguration, window:active_pane())
end

function M.toggle(window)
  M.set(window, not M.enabled())
end

return M
