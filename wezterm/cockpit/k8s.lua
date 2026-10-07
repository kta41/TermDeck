-- k8s.lua — entradas de la paleta para Kubernetes/K3s (kubectl puro).
-- Los comandos se escriben en el pane: historial y comportamiento normales.
-- Los selectores usan listas con timeout (si el API está caído avisan, no cuelgan).
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  if not ctx.caps.kubectl then
    return
  end
  local cwd = ctx.cwd
  add('K8s: pods', function(w, p) util.send(w, p, 'kubectl get pods') end)
  add('K8s: pods → describe', function(w, p)
    util.pick(w, p, {
      title = 'Pod → describe',
      ck_args = 'k8s pods --names',
      template = 'kubectl describe pod %s',
      cwd = cwd,
    })
  end)
  add('K8s: pods → logs (-f)', function(w, p)
    util.pick(w, p, {
      title = 'Pod → logs',
      ck_args = 'k8s pods --names',
      template = 'kubectl logs -f %s',
      cwd = cwd,
    })
  end)
  add('K8s: port-forward (pod)', function(w, p)
    util.pick(w, p, {
      title = 'Pod → port-forward (edita puertos antes de Enter)',
      ck_args = 'k8s pods --names',
      template = 'kubectl port-forward pod/%s 8080:80',
      enter = false, -- editable: ajusta los puertos antes de ejecutar
      cwd = cwd,
    })
  end)
  add('K8s: deployments', function(w, p) util.send(w, p, 'kubectl get deployments') end)
  add('K8s: deployment → rollout status', function(w, p)
    util.pick(w, p, {
      title = 'Deployment → rollout status',
      ck_args = 'k8s deployments --names',
      template = 'kubectl rollout status deployment/%s',
      cwd = cwd,
    })
  end)
  add('K8s: services', function(w, p) util.send(w, p, 'kubectl get services') end)
  add('K8s: events', function(w, p)
    util.send(w, p, 'kubectl get events --sort-by=.lastTimestamp')
  end)
  add('K8s: namespaces', function(w, p) util.send(w, p, 'kubectl get ns') end)
  add('K8s: namespace → cambiar', function(w, p)
    util.pick(w, p, {
      title = 'Cambiar namespace del contexto actual',
      ck_args = 'k8s namespaces --names',
      template = 'kubectl config set-context --current --namespace=%s',
      cwd = cwd,
    })
  end)
  add('K8s: contexts', function(w, p) util.send(w, p, 'kubectl config get-contexts') end)
  add('K8s: context → cambiar', function(w, p)
    util.pick(w, p, {
      title = 'Cambiar de contexto',
      ck_args = 'k8s contexts --names',
      template = 'kubectl config use-context %s',
      cwd = cwd,
    })
  end)
end

return M
