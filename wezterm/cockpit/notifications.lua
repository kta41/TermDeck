local runtime = require 'cockpit.runtime'

local M = {}

function M.read()
  local state = runtime.read('notifications.state')
  return {
    app = state.app or '',
    count = tonumber(state.count or '') or 0,
    severity = state.severity or 'info',
    summary = state.summary or '',
    deep_link = state.deep_link or '',
  }
end

function M.banner()
  local state = M.read()
  if state.app == '' or state.count <= 0 then
    return ''
  end
  return '  ' .. state.app .. ' · ' .. state.count .. ' · ' .. state.summary .. '  '
end

function M.focus(window)
  local state = M.read()
  if state.deep_link ~= '' then
    require('wezterm').open_with(state.deep_link)
  else
    window:toast_notification('cockpit', 'no hay deep link para ' .. (state.app ~= '' and state.app or 'la aplicación'), nil, 3000)
  end
end

function M.clear(window)
  local ok, err = runtime.write('notifications.state', { app = '', count = 0, summary = '', deep_link = '' })
  if not ok then
    window:toast_notification('cockpit', 'no se pudo limpiar notificaciones: ' .. tostring(err), nil, 4000)
    return
  end
  window:toast_notification('cockpit', 'notificaciones limpiadas', nil, 2500)
end

return M
