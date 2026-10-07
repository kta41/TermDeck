-- ci.lua — entradas de la paleta para CI/CD del repo actual.
-- Solo aparecen si el repo tiene CI detectado (.github/workflows o .gitlab-ci.yml).
-- `ck ci` decide internamente entre gh / glab / API pública (curl, solo lectura).
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  local gh = ctx.provider == 'github'
  local page = ctx.repo_url .. (gh and '/actions' or '/-/pipelines')
  local cwd = ctx.cwd

  add('CI: pipelines / runs', function(w, p) util.send(w, p, 'ck ci runs') end)
  add('CI: runs fallidos', function(w, p) util.send(w, p, 'ck ci failed') end)
  add('CI: run → logs', function(w, p)
    util.pick(w, p, {
      title = 'Run → logs',
      ck_args = 'ci ids',
      template = 'ck ci view %s',
      field = '^(%S+)', -- el primer campo de la línea es el id
      cwd = cwd,
    })
  end)
  add('CI: run → retry', function(w, p)
    util.pick(w, p, {
      title = 'Run → retry',
      ck_args = 'ci ids',
      template = 'ck ci rerun %s',
      field = '^(%S+)',
      cwd = cwd,
    })
  end)
  add('CI: abrir página web', function(w, p) util.open_url(w, page) end)
end

return M
