sky.use('core/page')
sky.use('io/norns')

local Deque = require('container/deque')
-- local Number = require('params/number')

-- local json = include('lib/dep/rxi-json/json')

pitches = {174.543, 264.179, 279.629, 341.805, 389.674, 413.943, 523.817, 552.483, 693.637}

local function snap_hz(hz, pitches)
  local dist = math.huge
  local snapped = 0
  local t = 0
  for i,pc in ipairs(pitches) do
    local delta = math.abs(pc - hz)
    if delta < dist then
      dist = delta
      snapped = pc
      t = i
    end
  end
  return snapped, t
end

function average(numbers)
  local sum = 0.0
  local t
  for i, n in ipairs(numbers) do
    sum = sum + n
    t = i
  end
  return sum / t
end

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

--
-- SlotWidget
--
local SlotWidget = sky.Object:extend()
SlotWidget.BOX_DIM = 8
SlotWidget.BOX_SEP = 3
SlotWidget.BOX_PAD = 4
SlotWidget.SELECTED_LEVEL = 10

function SlotWidget:new(x, y)
  self.topleft = {x or 1, y or 1}
end

--
-- NumWidget
--
local NumWidget = SlotWidget:extend()

function NumWidget:new(x, y, num)
  NumWidget.super.new(self, x, y)
  self.num = num
end

function NumWidget:draw(selected, num)
  local x = self.topleft[1]
  local y = self.topleft[2]
  local full_dim = self.BOX_PAD * 2 + self.BOX_SEP + self.BOX_DIM * 2
  local half_dim = full_dim / 2

  -- outer
  screen.move(x, y + 3)
  screen.line_rel(0, -3)
  screen.line_rel(full_dim - 1, 0)
  screen.line_rel(0, 3)
  screen.level(2)
  screen.stroke()
  screen.move(x + half_dim - 2, y + half_dim + 4)
  if selected then screen.level(self.SELECTED_LEVEL) end
  screen.font_size(16)
  screen.text_center(num or self.num)

  if selected then
    local dx = x + full_dim
    screen.move(x, y + full_dim)
    screen.line_rel(full_dim - 1, 0)
    screen.level(self.SELECTED_LEVEL)
    screen.close()
    screen.stroke()
  end
end


--
-- TunePage
--
local TunePage = sky.Page:extend()
TunePage.MAIN_LEVEL = 10
TunePage.DETECT_LEVEL = 4
TunePage.BUG_HI_LEVEL = 8
TunePage.BUG_LO_LEVEL = 1

function TunePage:new()
  TunePage.super.new(self)

  self.tuning = false

  self.pitch_num = 1
  self.pitch_index = 1
  self.pitch_values = {}

  self.detect_values = ShiftRegister(3)
  self.detect_value = nil
  self.detect_last = nil

  self._k1z = 0
  self._k3z = 0

  self.match_level = 12

  self.slot = NumWidget(128 - 26, 7, self.pitch_index)

  self.chain = sky.Chain{
    sky.OSCFunc{
      path = '/onsp',
      f = function(path, args, from, output)
        self:on_trigger(args[2])
      end,
    },
  }
end

function TunePage:on_trigger(hz)
  if self.tuning then
    self:detect_refine(hz)
  else
    local corrected, t = snap_hz(hz, self.pitch_values)
    self.detect_last = hz
    self.pitch_index = t
    self.match_level = 6
    engine.start(corrected)
  end
end

function TunePage:detect_start(index)
  self.pitch_index = index or self.pitch_index
  self.detect_values = ShiftRegister(3)
  self.detect_value = self.pitch_values[self.pitch_index]
  self.detect_last = nil
end

function TunePage:detect_stop()
  if self.detect_value then
    self.pitch_values[self.pitch_index] = self.detect_value
  end
end

function TunePage:detect_refine(pitch)
  self.detect_last = pitch
  self.detect_values:push(pitch)
  local a = average(self.detect_values:to_array())
  self.detect_value = a
end

function TunePage:draw_bug(top_left)
  local x = top_left[1]
  local y = top_left[2]

  -- box
  screen.level(self.BUG_LO_LEVEL)
  if self.tuning then
    screen.rect(x -1, y-1, 7, 8)
    screen.fill()
  else
    screen.rect(x, y, 6, 7)
    screen.stroke()
  end

  -- tuning fork
  -- if self.tuning then
    -- screen.level(0)
  -- else
    screen.level(self.BUG_HI_LEVEL)
  -- end
  screen.move(x + 2, y + 1) -- left
  screen.line_rel(0, 2)
  screen.move(x + 4, y + 1) -- right
  screen.line_rel(0, 2)
  screen.move(x + 3, y + 3) -- down
  screen.line_rel(0, 2)
  screen.stroke()
end

local function format_num(v, round, alt)
  if v then
    return '' .. util.round(v, round)
  end
  return alt or ''
end

function TunePage:get_effective_pitch()
  if self.tuning then
    return self.detect_value
  end
  return self.pitch_values[self.pitch_index]
end

function TunePage:draw_pitch(top_left)
  local x = top_left[1]
  local y = top_left[2]
  local median_size = 20

  -- median
  screen.move(x, y)
  -- screen.font_face(21)
  -- screen.font_size(15) --median_size)
  -- screen.font_face(49)
  -- screen.font_size(18) --median_size)
  screen.font_size(0)
  screen.font_size(16)
  screen.level(self.MAIN_LEVEL)
  screen.text(format_num(self:get_effective_pitch(), 0.01, '-'))

  -- last
  screen.move(x + 1, y + median_size / 2)
  screen.font_face(0)
  screen.font_size(8)
  screen.level(self.DETECT_LEVEL)
  screen.text('> ' .. format_num(self.detect_last, 0.01))
end

--[[
function TunePage:draw_slot()
  --self.slot:draw(false, self.pitch_index)
  -- self.slot:draw(true, 30)
  screen.move(14, 45)
  screen.font_face(0)
  screen.font_size(8)
  screen.level(self.MAIN_LEVEL)
  screen.text(self.pitch_index)
  screen.level(self.DETECT_LEVEL)
  screen.text(' /' .. self.pitch_num)
end
]]--

function TunePage:draw_slot(top_left)
  local x = top_left[1]
  local y = top_left[2]
  local median_size = 20

  -- index
  screen.move(x, y)
  screen.font_size(0)
  screen.font_size(16)
  screen.level(self.MAIN_LEVEL)
  screen.text(self.pitch_index)

  -- count
  screen.move(x + 1, y + median_size / 2)
  screen.font_face(0)
  screen.font_size(8)
  screen.level(self.DETECT_LEVEL)
  screen.text('/ ' .. self.pitch_num)
end

function TunePage:draw_match(bounds)
  if self.match_level < 1 then return end
  screen.level(self.match_level)
  screen.rect(13, 5, 128 - 15, 32)
  -- screen.move(13 + 4, 5)
  -- screen.line_rel(-5, 0)
  -- screen.line_rel(0)
  screen.stroke()
end

function TunePage:match_level_delta(d)
  if self.match_level > 0 then
    self.match_level = util.clamp(self.match_level + d, 0, 16)
  end
end

function TunePage:draw_header()
  -- box
  screen.level(4)
  screen.rect(0, 0, 7, 65)
  screen.fill()
  -- label
  screen.font_face(0)
  screen.font_size(8)
  screen.level(0)
  local msg = "detect"
  if self.tuning then msg = "tune" end
  screen.text_rotate(6, 62, msg, -90)
end

function TunePage:draw_footer()
  screen.font_face(0)
  screen.font_size(8)
  screen.level(3)
  screen.move(11, 62)
  screen.text("command")
end

function TunePage:draw(event, props)
  self:draw_header()
  self:draw_footer()
  self:draw_pitch({18, 20})
  self:draw_slot({98, 20})
  if not self.tuning then
    self:draw_match()
    self:match_level_delta(-2)
  end
  self:draw_bug({128 - 6, 64 - 7})
end

function TunePage:pitch_index_delta(d, extend)
  local v = self.pitch_index + d
  if extend and v > self.pitch_num then
    self.pitch_num = self.pitch_num + 1
  end
  self.pitch_index = util.clamp(v, 1, self.pitch_num)
end

function TunePage:pitch_index_set(i)
  self.pitch_index = util.clamp(i, 1, self.pitch_num)
end

function TunePage:process(event, output, state, props)
  if sky.is_key(event) then
    if event.n == 1 then
      self._k1z = event.z
    elseif event.n == 2 and event.z == 1 then
      self.tuning = not self.tuning -- toggle tuning
      if self.tuning then
        print('detect start')
        self:detect_start()
      else
        print('detect stop')
        self:detect_stop()
      end
    elseif event.n == 3 then
      self._k3z = event.z
      if event.z == 1 and self.tuning then
        -- advance pitch_index
        print('advance pitch index')
        self:detect_stop()
        self:pitch_index_delta(1, true)
        self:detect_start()
      end
    end
  elseif sky.is_enc(event) then
    if event.n == 2 then
      -- allow for manually adjusting the tuning value
      if self.tuning then
        -- print('adjust detection pitch')
        self.detect_value = util.clamp((self.detect_value or 0) + (event.delta * 0.2), 0, 20000)
      end
    elseif event.n == 3 then
      if self._k3z == 1 then
        self.pitch_num = util.clamp(self.pitch_num + event.delta, 1, 127)
        self:pitch_index_set(self.pitch_index) -- keep in range
      else
        self:pitch_index_delta(event.delta)
      end
    end
  else
    -- run events through the embedded chain, outputing to whatever chain this
    -- page is embeded in.
    self.chain:process(event, nil, output)
  end
end


--
-- Controller
--

local Controller = sky.Object:extend()

function Controller:new(model)
  self.model = model
end

function Controller:add_params()
  params:add_separator('rubia')
end

--
-- module
--
return {
  TunePage = TunePage,
  Controller = Controller,

  -- TODO: move this elsewhere
  ShiftRegister = ShiftRegister,
}