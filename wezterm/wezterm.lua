local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ============ Apariencia ============
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0
config.font_dirs = { 'fonts' }  -- carga TTFs desde el propio repo

-- Renderer GPU. Si ves parpadeos/glitches (drivers Intel antiguos): 'OpenGL'
config.front_end = 'WebGpu'

config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.scrollback_lines = 10000
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
-- config.tab_bar_at_bottom = true
-- Plan B: botones de ventana integrados en la tab bar
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }

-- Los botones viven en la tab bar → no se puede ocultar
config.hide_tab_bar_if_only_one_tab = false

-- Que la barra funda con el fondo (Catppuccin Mocha)
config.window_frame = {
  font = wezterm.font 'JetBrainsMono Nerd Font',
  font_size = 10.0,
  active_titlebar_bg = '#1e1e2e',
  inactive_titlebar_bg = '#1e1e2e',
}

-- Opcional W11: blur acrílico (requiere opacity < 1)
-- config.window_background_opacity = 0.92
-- config.win32_system_backdrop = 'Acrylic'

config.check_for_updates = false
config.warn_about_missing_glyphs = false

-- ============ WSL2 ============
-- Guard: si algún día abres esta config en Linux, no rompe
if wezterm.target_triple:find 'windows' then
  -- Debe coincidir EXACTAMENTE con `wsl -l -v`
  config.default_domain = 'WSL:Debian'

  -- Todas las distros arrancan en $HOME del Linux (no en /mnt/c)
  config.wsl_domains = wezterm.default_wsl_domains()
  for _, dom in ipairs(config.wsl_domains) do
    dom.default_cwd = '~'
  end
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
  -- Launcher: las distros WSL se añaden solas; añadimos shells Windows
  config.launch_menu = {
    { label = 'PowerShell 7', args = { 'pwsh.exe', '-NoLogo' } },
    { label = 'PowerShell 5', args = { 'powershell.exe', '-NoLogo' } },
  }
end

-- No cambies esto salvo que instales el terminfo de wezterm DENTRO de WSL
-- (comprueba con `infocmp wezterm`); si no, apps como vim/htop se ven mal
config.term = 'xterm-256color'

-- ============ Teclas estilo tmux ============
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

local ctrl_c_copy = wezterm.action_callback(function(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if sel and sel ~= '' then
    window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
  else
    window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
  end
end)
config.keys = {
  { key = 'c', mods = 'CTRL', action = ctrl_c_copy },
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'b', mods = 'CTRL|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
  { key = 'LeftArrow',  mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Left',  2 } },
  { key = 'RightArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Right', 2 } },
  { key = 'UpArrow',    mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Up',    2 } },
  { key = 'DownArrow',  mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Down',  2 } },
  { key = 'z', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
}

-- LEADER + 1..9 salta a la pestaña N (aquí es donde Lua brilla)
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

-- ============ Cockpit DevOps (capa modular) ============
-- Toda la funcionalidad nueva vive en wezterm/cockpit/*.lua (paleta LEADER+P,
-- status derecho, selectores). Si algo de esa capa falla, esta config base
-- sigue funcionando exactamente igual (por eso el pcall).
local cockpit_ok, cockpit = pcall(require, 'cockpit')
if cockpit_ok then
  cockpit.setup(config)
else
  wezterm.log_error('cockpit no disponible: ' .. tostring(cockpit))
end

return config