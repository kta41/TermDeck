-- argocd.lua — entradas de la paleta para ArgoCD según lo realmente disponible:
--   * estado 'ready' (CLI instalado + sesión válida) → operaciones completas
--   * sin CLI pero CRD en el clúster (argocd_kube=1) → solo lectura vía kubectl
--   * nada → no aparece en la paleta
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  local ar = ctx.state.argocd
  local kube_fallback = ctx.state.argocd_kube == '1'
  local cwd = ctx.cwd

  if ar == 'ready' then
    add('Argo: aplicaciones', function(w, p) util.send(w, p, 'argocd app list') end)
    add('Argo: app → detalle', function(w, p)
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
  elseif ar == 'absent' and kube_fallback then
    add('Argo: aplicaciones (solo lectura, kubectl)', function(w, p)
      util.send(w, p, 'kubectl get applications.argoproj.io -A')
    end)
  end
end

return M
