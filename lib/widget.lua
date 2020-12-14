--
-- Widget
--

local Widget = sky.Object:extend()

function Widget:new(rect)
  Widget.super.new(self)
  self._rect = rect
end

function Widget:to_global(x, y)
  return self._rect[1] + x, self._rect[2] + y
end

function Widget:to_local(x, y)
  return x - self._rect[1], y - self._rect[2]
end

-- function Widget:screen_move(x, y)
--   screen.move(self.to_global(x, y))
-- end

return Widget