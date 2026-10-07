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
-- config.window_decorations = 'RESIZE'  -- sin barra de título

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

config.keys = {
  -- Panes (siempre en el mismo dominio/distro que el pane actual)
  { key = 'd', mods = 'LEADER',         action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'LEADER|SHIFT',   action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'x', mods = 'LEADER',         action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER',         action = act.TogglePaneZoomState },
  { key = 'o', mods = 'LEADER',         action = act.ActivatePaneDirection 'Next' },

  -- Navegación vim-style
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Resize (mismo esquema en mayúsculas)
  { key = 'h', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left',  2 } },
  { key = 'j', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down',  2 } },
  { key = 'k', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up',    2 } },
  { key = 'l', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 2 } },

  -- Tabs y launcher
  { key = 't', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 's', mods = 'LEADER', action = act.ShowLauncher },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative( 1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },

  -- Clipboard / copy mode
  { key = 'y', mods = 'LEADER', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'LEADER|SHIFT', action = act.PasteFrom 'Clipboard' },
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
}

-- LEADER + 1..9 salta a la pestaña N (aquí es donde Lua brilla)
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

return config