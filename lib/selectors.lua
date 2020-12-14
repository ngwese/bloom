--
-- Selector
--

local Selector = sky.Object:extend()

function Selector:new(values_f, action_f)
  Selector.super.new(self)
  self.values_f = values_f
  self.action_f = action_f

  self.values = nil
  self.acc = 1
  self.selection = 1
  self.len = 0
end

function Selector:refresh()
  self.values = self.values_f()
  self.len = #self.values
end

function Selector:select(v)
  self.selection = util.clamp(math.floor(v), 1, self.len)
end

function Selector:value()
  if self.values then
    return self.values[self.selection]
  end
end

function Selector:bang()
  if self.action_f then
    self.action_f(self:value())
  end
end

local function gather_files(dir, glob, static)
  local t = {}
  local extn = string.gsub(glob, '*', '')
  local filter = function(results)
    for path in results:gmatch("[^\r\n]+") do
      local p = string.gsub(path, dir, '')
      p = string.gsub(p, extn, '')
      table.insert(t, p)
    end
  end
  local cmd = 'find ' .. dir .. ' -name "' .. glob .. '" | sort'
  filter(util.os_capture(cmd, true))
  if static then
    for _, v in ipairs(static) do
      table.insert(t, v)
    end
  end
  return t
end

local PatternSelector = Selector(function()
  return gather_files(paths.this.data, '*.pat.json', {'...'})
end)

local SetSelector = Selector(function()
  return gather_files(paths.this.data, '*.set.json', {'...'})
end)

return {
  Selector = Selector,
  gather_files = gather_files,
}