local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

function M.open(window, pane)
  window:perform_action(
    act.InputSelector {
      title = 'Terminal Cockpit · keyboard map',
      description = 'Esc closes this help',
      fuzzy = false,
      choices = {
        { id = 'CTRL+SHIFT+D       split side-by-side', label = 'CTRL+SHIFT+D       split side-by-side' },
        { id = 'CTRL+SHIFT+B       split top/bottom', label = 'CTRL+SHIFT+B       split top/bottom' },
        { id = 'CTRL+SHIFT+W       close current pane', label = 'CTRL+SHIFT+W       close current pane' },
        { id = 'CTRL+C / CTRL+V    copy / paste', label = 'CTRL+C / CTRL+V    copy / paste' },
        { id = 'CTRL+P             Cockpit palette', label = 'CTRL+P             Cockpit palette' },
        { id = 'CTRL+H             this help', label = 'CTRL+H             this help' },
        { id = 'CTRL+A then P      Cockpit palette', label = 'CTRL+A then P      Cockpit palette' },
        { id = 'F9                 Cockpit palette', label = 'F9                 Cockpit palette' },
        { id = 'LEADER = CTRL+A    release, then press the next key', label = 'LEADER = CTRL+A    release, then press the next key' },
        { id = 'Right-click +      WezTerm launcher menu', label = 'Right-click +      WezTerm launcher menu' },
        { id = 'Palette: save layout', label = 'Palette: save layout' },
        { id = 'Palette: focus mode', label = 'Palette: enable/disable focus mode' },
        { id = 'Palette: attach desktop app', label = 'Palette: attach desktop app (overlay)' },
        { id = 'Palette: detach desktop app', label = 'Palette: detach desktop app' },
        { id = 'Palette: focus/clear notifications', label = 'Palette: focus or clear notifications' },
        { id = 'Status bar          Kubernetes / Argo context', label = 'Status bar          Kubernetes / Argo context' },
        { id = 'Esc                close this help', label = 'Esc                close this help' },
      },
      action = wezterm.action_callback(function() end),
    },
    pane
  )
end

return M
