local M = {}

local function path(name)
  return (os.getenv('TEMP') or os.getenv('TMP') or '.') .. '\\termdeck-' .. name
end

function M.read(name)
  local result = {}
  local file = io.open(path(name), 'r')
  if not file then
    return result
  end
  for line in file:lines() do
    local key, value = line:match '^([%w_]+)=(.*)$'
    if key then
      result[key] = value
    end
  end
  file:close()
  return result
end

function M.write(name, values)
  local file, err = io.open(path(name), 'w')
  if not file then
    return false, err
  end
  for key, value in pairs(values) do
    file:write(key, '=', tostring(value), '\n')
  end
  file:close()
  return true
end

function M.path(name)
  return path(name)
end

return M
