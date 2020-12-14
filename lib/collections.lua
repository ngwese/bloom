local Deque = require('container/deque')

--
-- ShiftRegister
--
local ShiftRegister = sky.Object:extend()

function ShiftRegister:new(size, on_spill)
  self._elements = Deque.new()
  self.size = size or 8
  self.on_spill = on_spill or function(...) end
end

function ShiftRegister:push(item)
  self._elements:push(item)
  local c = self._elements:count() - self.size
  for i = 1, c do
    self.on_spill(self._elements:pop_back())
  end
end

function ShiftRegister:ipairs()
  return self._elements:ipairs()
end

function ShiftRegister:to_array()
  return self._elements:to_array()
end

return {
  ShiftRegister = ShiftRegister,
}