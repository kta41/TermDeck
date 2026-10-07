-- util.lua — helpers de UI de la capa WezTerm: enviar comandos al pane,
-- selectores encadenados (InputSelector) y avisos (toasts).
local wezterm = require 'wezterm'
local act = wezterm.action
local wsl = require 'cockpit.wsl'

local M = {}

function M.toast(window, msg)
  window:toast_notification('cockpit', msg, nil, 3000)
end

-- Envía texto al pane activo, por defecto con Enter al final.
-- enter = false para dejar el comando editable (p.ej. port-forward).
function M.send(window, pane, text, enter)
  local s = text
  if enter ~= false then
    s = s .. '\r'
  end
  window:perform_action(act.SendString { string = s }, pane)
end

-- Abre una URL con el navegador por defecto de Windows.
function M.open_url(window, url)
  if not url or url == '' then
    M.toast(window, 'sin URL (¿remote sin proveedor reconocido?)')
    return
  end
  wezterm.open_with(url)
end

-- Selector encadenado: ejecuta un subcomando de ck en WSL, muestra un
-- InputSelector difuso y envía template con lo elegido.
-- p = { title, ck_args, template, field, enter, cwd }
--   field   patrón Lua para extraer la parte que se sustituye ('^(%S+)')
--   enter   false → sin Enter (editable)
function M.pick(window, pane, p)
  local out = wsl.ck(p.ck_args, { cwd = p.cwd })
  if not out then
    M.toast(window, p.title .. ': WSL no disponible')
    return
  end
  local entries = {}
  for line in out:gmatch '[^\r\n]+' do
    if line ~= '' then
      table.insert(entries, { label = line, id = line })
    end
  end
  if #entries == 0 then
    M.toast(window, p.title .. ': sin resultados o no disponible')
    return
  end
  window:perform_action(
    act.InputSelector {
      title = p.title,
      description = 'Enter para elegir · Esc para cancelar',
      fuzzy = true,
      entries = entries,
      action = wezterm.action_callback(function(w2, p2, _, sel)
        if sel and sel ~= '' then
          local chosen = sel
          if p.field then
            chosen = sel:match(p.field) or sel
          end
          local pre, post = p.template:match '^(.*)%%s(.*)$'
          if pre then
            M.send(w2, p2, pre .. chosen .. post, p.enter)
          else
            M.send(w2, p2, p.template .. chosen, p.enter)
          end
        end
      end),
    },
    pane
  )
end

return M
