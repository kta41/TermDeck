-- pr.lua — palette entries for GitHub pull requests via the gh CLI.
-- Only shown when the remote provider is github and gh is installed.
local wezterm = require 'wezterm'
local act = wezterm.action
local util = require 'cockpit.util'

local M = {}

function M.build(add, ctx)
  add('PR: list', function(w, p) util.send(w, p, 'gh pr list') end)
  add('PR: create (title + body)', function(w, p)
    w:perform_action(
      act.PromptInputLine {
        -- NOTE: this build has no `action_title`; description only
        description = 'gh pr create — title',
        action = wezterm.action_callback(function(w2, p2, title)
          if not title or title == '' then
            return
          end
          w2:perform_action(
            act.PromptInputLine {
              description = 'gh pr create — body (empty = --fill from commits)',
              action = wezterm.action_callback(function(w3, p3, body)
                local bodyflag = '--fill'
                if body and body ~= '' then
                  bodyflag = '--body "' .. body .. '"'
                end
                util.send(w3, p3, 'gh pr create --title "' .. title .. '" ' .. bodyflag)
              end),
            },
            p2
          )
        end),
      },
      p
    )
  end)
  add('PR: checks (current branch)', function(w, p) util.send(w, p, 'gh pr checks') end)
  add('PR: merge (editable flags)', function(w, p)
    util.send(w, p, 'gh pr merge ', false) -- no Enter: add --squash/--delete-branch first
  end)
end

return M
