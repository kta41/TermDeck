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

-- Runs a command in a new vertical split pane (same WSL domain as the current
-- pane). Your pane stays intact; close the split later with CTRL+SHIFT+W.
-- Split mode always presses Enter (editability only makes sense in-pane).
function M.split_run(window, pane, cmd)
  local ok = pcall(function()
    window:perform_action(act.SplitVertical { domain = 'CurrentPaneDomain' }, pane)
    -- SplitVertical focuses the new pane; it becomes the active one
    local target = window:active_pane()
    if target and target:pane_id() ~= pane:pane_id() then
      window:perform_action(act.SendString { string = cmd .. '\r' }, target)
    else
      -- fallback: the split did not focus in time, type into the current pane
      M.send(window, pane, cmd)
    end
  end)
  if not ok then
    M.send(window, pane, cmd)
  end
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
          local text = pre and (pre .. chosen .. post) or (p.template .. chosen)
          if p.split then
            M.split_run(w2, p2, text)
          else
            M.send(w2, p2, text, p.enter)
          end
        end
      end),
    },
    pane
  )
end

return M
