-- util.lua — UI helpers for the WezTerm layer: send commands to the pane,
-- chained pickers (InputSelector) and notifications (toasts).
local wezterm = require 'wezterm'
local act = wezterm.action
local wsl = require 'cockpit.wsl'

local M = {}

function M.toast(window, msg)
  window:toast_notification('cockpit', msg, nil, 3000)
end

-- Sends text to the active pane, with Enter by default.
-- enter = false leaves the command editable (e.g. port-forward).
function M.send(window, pane, text, enter)
  local s = text
  if enter ~= false then
    s = s .. '\r'
  end
  window:perform_action(act.SendString { string = s }, pane)
end

-- Opens a URL with the Windows default browser.
function M.open_url(window, url)
  if not url or url == '' then
    M.toast(window, 'no URL (unrecognized remote provider?)')
    return
  end
  wezterm.open_with(url)
end

-- Chained picker: runs a ck subcommand inside WSL, shows a fuzzy
-- InputSelector and sends template with the selection.
-- p = { title, ck_args, template, field, enter, cwd }
--   field   Lua pattern to extract the substituted part ('^(%S+)')
--   enter   false → no Enter (editable)
function M.pick(window, pane, p)
  local out = wsl.ck(p.ck_args, { cwd = p.cwd })
  if not out then
    M.toast(window, p.title .. ': WSL unavailable')
    return
  end
  local entries = {}
  for line in out:gmatch '[^\r\n]+' do
    if line ~= '' then
      table.insert(entries, { label = line, id = line })
    end
  end
  if #entries == 0 then
    M.toast(window, p.title .. ': no results or unavailable')
    return
  end
  window:perform_action(
    act.InputSelector {
      title = p.title,
      description = 'Enter to select · Esc to cancel',
      fuzzy = true,
      entries = entries,
      action = wezterm.action_callback(function(w2, p2, _, sel)
        if sel and sel ~= '' then
          local chosen = sel
          if p.field then
            chosen = sel:match(p.field) or sel
          end
          local pre, post = p.template:match '^(.*)%%s(.*)$'
          if pre then
            M.send(w2, p2, pre .. chosen .. post, p.enter)
          else
            M.send(w2, p2, p.template .. chosen, p.enter)
          end
        end
      end),
    },
    pane
  )
end

return M
