-- argocd.lua — palette entries for ArgoCD based on what is actually available:
--   * state 'ready' (CLI installed + valid session) → full operations
--   * no CLI but applications CRD in-cluster (argocd_kube=1) → kubectl read-only
--   * nothing → not shown in the palette
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  local ar = ctx.state.argocd
  local kube_fallback = ctx.state.argocd_kube == '1'
  local cwd = ctx.cwd

  if ar == 'ready' then
    add('Argo: applications', function(w, p) util.send(w, p, 'argocd app list') end)
    add('Argo: app → get', function(w, p)
      util.pick(w, p, {
        title = 'App → get',
        ck_args = 'argocd names',
        template = 'argocd app get %s',
        cwd = cwd,
      })
    end)
    add('Argo: app → sync', function(w, p)
      util.pick(w, p, {
        title = 'App → sync',
        ck_args = 'argocd names',
        template = 'argocd app sync %s',
        cwd = cwd,
      })
    end)
    add('Argo: app → refresh', function(w, p)
      util.pick(w, p, {
        title = 'App → refresh',
        ck_args = 'argocd names',
        template = 'argocd app refresh %s',
        cwd = cwd,
      })
    end)
    add('Argo: app → history', function(w, p)
      util.pick(w, p, {
        title = 'App → history',
        ck_args = 'argocd names',
        template = 'argocd app history %s',
        cwd = cwd,
      })
    end)
    add('Argo: app → logs', function(w, p)
      util.pick(w, p, {
        title = 'App → logs',
        ck_args = 'argocd names',
        template = 'argocd app logs %s',
        cwd = cwd,
      })
    end)
    add('Argo: app → logs (split)', function(w, p)
      util.pick(w, p, {
        title = 'App → logs (new split pane)',
        ck_args = 'argocd names',
        template = 'argocd app logs %s',
        split = true,
        cwd = cwd,
      })
    end)
    add('Argo: app → sync (split)', function(w, p)
      util.pick(w, p, {
        title = 'App → sync (new split pane)',
        ck_args = 'argocd names',
        template = 'argocd app sync %s',
        split = true,
        cwd = cwd,
      })
    end)
  elseif ar == 'absent' and kube_fallback then
    add('Argo: applications (read-only, kubectl)', function(w, p)
      util.send(w, p, 'kubectl get applications.argoproj.io -A')
    end)
  end
end

return M
