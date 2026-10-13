local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local function cwd_label(pane)
  local ok, cwd = pcall(function()
    return pane.current_working_dir
  end)
  if not ok or not cwd then
    return 'WSL'
  end
  local path = tostring(cwd):gsub('^wsl://[^/]+', ''):gsub('^file://[^/]*', '')
  path = path:gsub('/+$', '')
  if path == '' or path == '/home/Kta41' then
    return '~'
  end
  return path:match('([^/]+)$') or 'WSL'
end

-- Bash emits OSC 2 with "directory > command"; never display the WSL host
-- process name as a tab title.
wezterm.on('format-tab-title', function(tab)
  local title = tab.active_pane.title
  if title and title ~= '' and title ~= 'wslhost.exe' then
    return title
  end
  return cwd_label(tab.active_pane) .. ' > shell'
end)

-- ============ Appearance ============
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0
config.font_dirs = { 'fonts' }  -- load TTFs from this repo

-- GPU renderer. If you see flicker/glitches (old Intel drivers): 'OpenGL'
config.front_end = 'WebGpu'

config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.scrollback_lines = 10000
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
-- The + button creates a tab with left click and opens the launcher menu
-- with right click. Keep it visible even when the tab bar has one tab.
config.show_new_tab_button_in_tab_bar = true
-- config.tab_bar_at_bottom = true
-- Plan B: window buttons integrated into the tab bar
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }

-- Buttons live in the tab bar -> it cannot be hidden
config.hide_tab_bar_if_only_one_tab = false

-- Make the bar blend with the background (Catppuccin Mocha)
config.window_frame = {
  font = wezterm.font 'JetBrainsMono Nerd Font',
  font_size = 10.0,
  active_titlebar_bg = '#1e1e2e',
  inactive_titlebar_bg = '#1e1e2e',
}

-- Optional W11: acrylic blur (requires opacity < 1)
-- config.window_background_opacity = 0.92
-- config.win32_system_backdrop = 'Acrylic'

config.check_for_updates = false
config.warn_about_missing_glyphs = false

-- ============ WSL2 ============
-- Guard: if you ever open this config on Linux, it won't break
if wezterm.target_triple:find 'windows' then
  -- Must match `wsl -l -v` EXACTLY
  config.default_domain = 'WSL:Debian'

  -- All distros start in the Linux $HOME (not /mnt/c)
  config.wsl_domains = {
    {
      name = 'WSL:Debian',
      distribution = 'Debian',
      username = 'Kta41',
      default_cwd = '~',
      default_prog = { '/bin/bash', '--rcfile', '/mnt/c/dev/dotfiles/scripts/wezterm-bashrc', '-i' },
    },
  }
  config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
  -- Launcher: WSL distros add themselves; we add Windows shells
  config.launch_menu = {
    {
      label = 'Debian (WSL)',
      domain = { DomainName = 'WSL:Debian' },
      args = { '/bin/bash', '--rcfile', '/mnt/c/dev/dotfiles/scripts/wezterm-bashrc', '-i' },
    },
    { label = 'PowerShell 7', args = { 'pwsh.exe', '-NoLogo' } },
    { label = 'PowerShell 5', args = { 'powershell.exe', '-NoLogo' } },
    -- session layer of the cockpit (binary path kept in sync with cockpit/config.lua)
    { label = 'Zellij (cockpit session)', args = { 'wsl.exe', '-d', 'Debian', '--', '/home/Kta41/.local/bin/zellij', 'attach', '--create', 'cockpit' } },
  }
end

-- Don't change this unless you install wezterm's terminfo INSIDE WSL
-- (check with `infocmp wezterm`); otherwise apps like vim/htop look wrong
config.term = 'xterm-256color'

-- ============ tmux-style keys ============
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

-- LEADER + 1..9 jumps to tab N (this is where Lua shines)
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'LEADER',
    action = act.ActivateTab(i - 1),
  })
end

-- ============ Cockpit DevOps (modular layer) ============
-- All new functionality lives in wezterm/cockpit/*.lua (LEADER+P palette,
-- right status bar, pickers). If that layer ever fails, this base config
-- keeps working exactly the same (hence the pcall).
local cockpit_ok, cockpit = pcall(require, 'cockpit')
if cockpit_ok then
  cockpit.setup(config)
else
  wezterm.log_error('cockpit no disponible: ' .. tostring(cockpit))
end

return config