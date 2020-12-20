local Widget = include('lib/widget')

--
-- ActionWidget
--

local ActionWidget = Widget:extend()
ActionWidget.VALUE_INSET = {6, 10}
ActionWidget.ACTION_LEVEL = 4
ActionWidget.VALUE_LEVEL = 10

function ActionWidget:new(rect, actions)
  ActionWidget.super.new(self, rect)
  self._actions = actions
  self._which_acc = 1.5
  self:select(1)
  self._what_acc = 1
  self:selector_delta(1)
end

function ActionWidget:selection_delta(d)
  self._which_acc = util.clamp(self._which_acc + d, 1, #self._actions)
  self:select(self._which_acc)
end

function ActionWidget:select(i)
  self._which = util.clamp(math.floor(i), 1, #self._actions)
  self._selector = self:selected()[2]
end

function ActionWidget:selected()
  return self._actions[self._which]
end

function ActionWidget:selected_name()
  return self:selected()[1]
end

function ActionWidget:selected_value()
  if self._selector then
    return self._selector:value()
  end
  return ''
end

function ActionWidget:selector_delta(d)
  if self._selector then
    self._what_acc = util.clamp(self._what_acc + d, 1, self._selector.len)
    self._selector:select(self._what_acc)
  end
end

function ActionWidget:selected_handler()
  return self._actions[self._which][3]
end

function ActionWidget:draw_action()
  screen.level(self.ACTION_LEVEL)
  screen.font_face(0)
  screen.font_size(8)
  -- screen.move(4, 48)
  -- local x, y = self:to_global(self._rect[1], self._rect[2])
  screen.move(self._rect[1], self._rect[2])
  screen.text(self:selected_name())
end

function ActionWidget:draw_value()
  local v = self:selected_value()
  if v then
    screen.level(self.VALUE_LEVEL)
    screen.font_face(0)
    screen.font_size(8)
    -- screen.move(10, 58)
    local x, y = self:to_global(self.VALUE_INSET[1], self.VALUE_INSET[2])
    screen.move(x, y)
    screen.text(v)
  end
end

function ActionWidget:draw()
  self:draw_action()
  self:draw_value()
end

return ActionWidget
