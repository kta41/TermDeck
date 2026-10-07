-- palette.lua — cockpit action palette (LEADER+P).
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

-- tool capabilities (`ck doctor -q`), cached for cfg.caps_ttl seconds
local caps_cache, caps_time = nil, 0
local function caps()
  if caps_cache and (os.time() - caps_time) < cfg.caps_ttl then
    return caps_cache
  end
  caps_cache = {}
  local out = wsl.ck('doctor -q') or ''
  for k, v in out:gmatch '(%w+)=(%d)' do
    caps_cache[k] = (v == '1')
  end
  caps_time = os.time()
  return caps_cache
end

function M.open(window, pane)
  if not wsl.pane_is_wsl(pane) then
    util.toast(window, 'cockpit: open the palette in a WSL (' .. cfg.distro .. ') pane')
    return
  end

  local cwd = wsl.pane_cwd(pane)
  local c = caps()
  local state = wsl.read_state()

  -- current repo context (local detection: files + remote, no network)
  local provider, repo_url = 'none', ''
  local in_repo = false
  if c.git then
    local pout = wsl.ck('git provider -q') or ''
    provider = pout:match 'provider=(%S+)' or 'none'
    repo_url = pout:match 'url=(%S*)' or ''
    local isrepo = wsl.run('git rev-parse --is-inside-work-tree 2>/dev/null', { cwd = cwd }) or ''
    in_repo = isrepo:find 'true' ~= nil
  end

  -- CI of the current repo (empty → the section stays hidden)
  local ci = {}
  if in_repo then
    local cout = wsl.ck('ci detect -q') or ''
    for k, v in cout:gmatch '(%w+)=(%S*)' do
      ci[k] = v
    end
  end

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

  local entries, actions = {}, {}
  local function add(label, fn)
    table.insert(entries, { id = tostring(#actions + 1), label = label })
    actions[tostring(#actions + 1)] = fn
  end

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
  if ci.ci and ci.ci ~= 'none' then
    cimod.build(add, ctx)
  end
  if in_repo and ctx.provider == 'github' and c.gh then
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
end

return M
