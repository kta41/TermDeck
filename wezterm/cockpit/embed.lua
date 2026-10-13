local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = require 'cockpit.config'

local M = {}

local function helper(args)
  local argv = { 'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', cfg.windows_helper }
  for _, value in ipairs(args) do
    table.insert(argv, value)
  end
  local ok, output = wezterm.run_child_process(argv)
  if not ok then
    return nil, 'Windows helper failed'
  end
  return output
end

function M.open(window)
  local output, err = helper { '-Action', 'list' }
  if not output then
    window:toast_notification('cockpit', err, nil, 4000)
    return
  end
  local choices, handles = {}, {}
  for line in output:gmatch '[^\r\n]+' do
    local handle, process, title = line:match '^(%d+)\t([^\t]+)\t(.+)$'
    if handle and title then
      local label = process .. ' · ' .. title
      table.insert(choices, { id = handle, label = label })
      handles[handle] = true
    end
  end
  if #choices == 0 then
    window:toast_notification('cockpit', 'No hay ventanas visibles seleccionables.', nil, 4000)
    return
  end
  window:perform_action(act.InputSelector {
    title = 'Attach desktop app (overlay WezTerm)',
    description = 'Selecciona una ventana · Esc cancela',
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(w, _, _, id, label)
      local selected = handles[id] and id or label
      if not selected or not handles[selected] then
        w:toast_notification('cockpit', 'No se pudo identificar la ventana seleccionada.', nil, 4000)
        return
      end
      local _, attach_err = helper { '-Action', 'attach', '-Handle', selected }
      if attach_err then
        w:toast_notification('cockpit', attach_err, nil, 4000)
      else
        w:toast_notification('cockpit', 'Aplicación superpuesta sobre WezTerm.', nil, 2500)
      end
    end),
  }, window:active_pane())
end

function M.detach(window)
  local _, err = helper { '-Action', 'detach' }
  if err then
    window:toast_notification('cockpit', err, nil, 4000)
  else
    window:toast_notification('cockpit', 'Overlay liberado.', nil, 2500)
  end
end

return M
