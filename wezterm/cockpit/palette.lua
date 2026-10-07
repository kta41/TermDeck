-- palette.lua — paleta de acciones del cockpit (LEADER+P).
-- Regla de oro: solo se listan operaciones implementadas Y disponibles ahora
-- mismo (herramientas instaladas, repo actual, proveedor del remote, clúster).
local wezterm = require 'wezterm'
local act = wezterm.action
local cfg = require 'cockpit.config'
local wsl = require 'cockpit.wsl'
local util = require 'cockpit.util'
local gitmod = require 'cockpit.git'
local k8smod = require 'cockpit.k8s'
local argomod = require 'cockpit.argocd'
local cimod = require 'cockpit.ci'

local M = {}

-- capacidades de herramientas (`ck doctor -q`), cacheadas cfg.caps_ttl s
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
    util.toast(window, 'cockpit: usa la paleta en un pane de WSL (' .. cfg.distro .. ')')
    return
  end

  local cwd = wsl.pane_cwd(pane)
  local c = caps()
  local state = wsl.read_state()

  -- contexto del repo actual (detección local: archivos + remote, sin red)
  local provider, repo_url = 'none', ''
  local in_repo = false
  if c.git then
    local pout = wsl.ck('git provider -q') or ''
    provider = pout:match 'provider=(%S+)' or 'none'
    repo_url = pout:match 'url=(%S*)' or ''
    local isrepo = wsl.run('git rev-parse --is-inside-work-tree 2>/dev/null', { cwd = cwd }) or ''
    in_repo = isrepo:find 'true' ~= nil
  end

  -- CI del repo actual (vacío → la sección no aparece)
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

  add('Cockpit: refrescar estado', function(w, p)
    wsl.ck('status --force')
    util.toast(w, 'estado refrescado')
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

  window:perform_action(
    act.InputSelector {
      title = 'Cockpit',
      description = 'escribe para filtrar (difuso) · Esc cancela',
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
