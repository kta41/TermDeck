-- ci.lua — palette entries for the CI/CD of the current repo.
-- Only shown when the repo has detected CI (.github/workflows or .gitlab-ci.yml).
-- `ck ci` internally picks gh / glab / the public API (curl, read-only).
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  local gh = ctx.provider == 'github'
  local page = ctx.repo_url .. (gh and '/actions' or '/-/pipelines')
  local cwd = ctx.cwd

  add('CI: pipelines / runs', function(w, p) util.send(w, p, 'ck ci runs') end)
  add('CI: failed runs', function(w, p) util.send(w, p, 'ck ci failed') end)
  add('CI: run → logs', function(w, p)
    util.pick(w, p, {
      title = 'Run → logs',
      ck_args = 'ci ids',
      template = 'ck ci view %s',
      field = '^(%S+)', -- the first field of the line is the id
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
  add('CI: open web page', function(w, p) util.open_url(w, page) end)
end

return M
