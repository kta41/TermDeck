-- git.lua — palette entries for Git (plain git, nothing fancy).
local wezterm = require 'wezterm'
local act = wezterm.action
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  local cwd = ctx.cwd
  add('Git: status', function(w, p) util.send(w, p, 'git status') end)
  add('Git: diff', function(w, p) util.send(w, p, 'git diff') end)
  add('Git: diff (staged)', function(w, p) util.send(w, p, 'git diff --cached') end)
  add('Git: log', function(w, p) util.send(w, p, 'git log --oneline --graph --decorate -20') end)
  add('Git: pull', function(w, p) util.send(w, p, 'git pull') end)
  add('Git: push', function(w, p) util.send(w, p, 'git push') end)
  add('Git: sync (add + commit + push)', function(w, p)
    w:perform_action(
      act.PromptInputLine {
        -- NOTE: this build has no `action_title`; description only
        description = 'git sync — commit message (adds all changes, commits, pushes)',
        action = wezterm.action_callback(function(w2, p2, line)
          if not line or line == '' then
            return
          end
          local msg = line:gsub('"', "'") -- keep the typed command safe
          util.send(w2, p2, 'git add -A && git commit -m "' .. msg .. '" && git push')
        end),
      },
      p
    )
  end)
  add('Git: stash list', function(w, p) util.send(w, p, 'git stash list') end)
  add('Git: stash push', function(w, p) util.send(w, p, 'git stash push') end)
  add('Git: stash pop', function(w, p) util.send(w, p, 'git stash pop') end)
  add('Git: branch → switch', function(w, p)
    util.pick(w, p, {
      title = 'Switch branch',
      ck_args = 'git branches',
      template = 'git switch %s',
      cwd = cwd,
    })
  end)

  -- provider web pages detected from the remote (github / gitlab)
  if ctx.provider == 'github' or ctx.provider == 'gitlab' then
    local pulls = ctx.provider == 'github' and '/pulls' or '/-/merge_requests'
    add('Repo: open in browser', function(w, p)
      util.open_url(w, ctx.repo_url)
    end)
    add('Repo: open PRs / MRs', function(w, p)
      util.open_url(w, ctx.repo_url .. pulls)
    end)
  end
end

return M
