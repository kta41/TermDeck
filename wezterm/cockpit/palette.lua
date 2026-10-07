-- palette.lua — cockpit action palette (LEADER+P or F9).
-- Golden rule: only implemented AND currently available operations are
-- listed (installed tools, current repo, remote provider, cluster).
local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = require 'cockpit.config'
local wsl = require 'cockpit.wsl'
local util = require 'cockpit.util'
local gitmod = require 'cockpit.git'
local k8smod = require 'cockpit.k8s'
local argomod = require 'cockpit.argocd'
local cimod = require 'cockpit.ci'
local prmod = require 'cockpit.pr'

local M = {}

-- TEMPORARY DEBUG (remove after diagnosing): appends to %TEMP%\cockpit-debug.log
local function dbg(msg)
  pcall(function()
    local p = (os.getenv('TEMP') or '.') .. '\\cockpit-debug.log'
    local f = io.open(p, 'a')
    if f then
      f:write(os.date('%H:%M:%S') .. ' [palette] ' .. msg .. '\n')
      f:close()
    end
  end)
end

dbg('module loaded (palette v2: LEADER+P and F9)')

function M.open(window, pane)
  local okd, dom = pcall(function()
    return pane:get_domain_name()
  end)
  dbg('triggered: domain=' .. tostring(okd and dom or 'ERROR'))

  local entries, actions = {}, {}
  local function add(label, fn)
    table.insert(entries, { id = tostring(#actions + 1), label = label })
    actions[tostring(#actions + 1)] = fn
  end

  if not wsl.pane_is_wsl(pane) then
    -- never bail out silently: still open the palette, with a notice on top
    add('Cockpit: pane is not WSL (' .. cfg.distro .. ') — K8s/Argo/PR need a WSL pane', function() end)
  end

  local ok, err = pcall(function()
    local cwd = wsl.pane_cwd(pane)
    local state = wsl.read_state()

    -- ONE fast spawn for all detection (local only, no network): caps, repo,
    -- provider and CI. Slow WSL cold starts only delay this single call.
    local out = wsl.ck('palette', { cwd = cwd }) or ''
    local c = {}
    for k, v in out:gmatch '([%w_]+)=(%S*)' do
      c[k] = v
    end
    c.git = c.git == '1'
    c.kubectl = c.kubectl == '1'
    c.gh = c.gh == '1'
    local in_repo = c.in_repo == '1'
    local provider = (c.provider ~= '' and c.provider) or 'none'
    local repo_url = c.url or ''
    local ci = {
      ci = (c.ci ~= '' and c.ci) or 'none',
      provider = provider,
    }

    local ctx = {
      window = window,
      pane = pane,
      cwd = cwd,
      caps = c,
      state = state,
      in_repo = in_repo,
      provider = provider,
      repo_url = repo_url,
      ci = ci,
    }

    add('Cockpit: refresh status', function(w, p)
      wsl.ck('status --force')
      util.toast(w, 'status refreshed')
    end)

    if in_repo and c.git then
      gitmod.build(add, ctx)
    end
    if c.kubectl then
      k8smod.build(add, ctx)
    end
    argomod.build(add, ctx)
    if ci.ci ~= 'none' then
      cimod.build(add, ctx)
    end
    if in_repo and provider == 'github' and c.gh then
      prmod.build(add, ctx)
    end

    window:perform_action(
      act.InputSelector {
        title = 'Cockpit',
        description = 'type to filter (fuzzy) · Esc cancels',
        fuzzy = true,
        entries = entries,
        action = wezterm.action_callback(function(w2, p2, _, id)
          local fn = actions[id]
          if fn then
            fn(w2, p2)
          end
        end),
      },
      pane
    )
  end)

  if not ok then
    dbg('ERROR: ' .. tostring(err))
    util.toast(window, 'cockpit palette error: ' .. tostring(err):sub(1, 120))
    wezterm.log_error('palette: ' .. tostring(err))
  else
    dbg('selector shown with ' .. tostring(#entries) .. ' entries')
  end
end

return M
