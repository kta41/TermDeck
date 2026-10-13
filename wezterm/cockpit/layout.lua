local runtime = require 'cockpit.runtime'

local M = {}

local function safe_name(name)
  return (name or 'default'):gsub('[^%w_-]', '_')
end

function M.save(window, pane, name)
  local file_name = 'layout-' .. safe_name(name) .. '.state'
  local cwd = tostring(pane.current_working_dir or '')
  local ok, err = runtime.write(file_name, {
    name = name,
    pane_id = pane:pane_id(),
    cwd = cwd,
    saved_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
  })
  if not ok then
    window:toast_notification('cockpit', 'no se pudo guardar layout: ' .. tostring(err), nil, 4000)
    return
  end
  window:toast_notification('cockpit', 'layout guardado: ' .. name, nil, 2500)
end

function M.prompt_save(window, pane)
  window:perform_action(require('wezterm').action.PromptInputLine {
    description = 'Nombre del layout',
    action = require('wezterm').action_callback(function(w, p, line)
      if line and line ~= '' then
        M.save(w, p, line)
      end
    end),
  }, pane)
end

return M
