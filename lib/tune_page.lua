sky.use('core/page')
sky.use('io/norns')

local collections = include('lib/collections')
local selectors = include('lib/selectors')
local ActionWidget = include('lib/action_widget')

-- local json = include('lib/dep/rxi-json/json')

pitches = {174.543, 264.179, 279.629, 341.805, 389.674, 413.943, 523.817, 552.483, 693.637}

local function snap_hz(hz, pitches, epsilon)
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
  if epsilon and dist > epsilon then
    return hz, 0
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

local TuningSelector = selectors.Selector(function()
  return selectors.gather_files(paths.this.data, '*.tune.jaon', {'...'})
end)

local ScalaSelector = selectors.Selector(function()
  return selectors.gather_files(paths.this.data, '*.scala', {'...'})
end)

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

  self.detect_values = collections.ShiftRegister(3)
  self.detect_value = nil
  self.detect_last = nil

  self._k1z = 0
  self._k3z = 0

  self.match_level = 12

  self.actions = ActionWidget({16, 50}, {
    {'load tuning:', TuningSelector, self.do_load_tuning},
    {'save tuning:', TuningSelector, self.do_save_tuning},
    {'load scala:', ScalaSelector, self.do_load_scala},
  })

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
    self.detect_last = hz
    local epsilon_hz = 50
    local corrected, t = snap_hz(hz, self.pitch_values, epsilon_hz)
    self.pitch_index = t
    if t > 0 then
      self.match_level = 6
      engine.start(corrected)
    end
  end
end

function TunePage:enter(props)
  print('refresh start')
  ScalaSelector:refresh()
  TuningSelector:refresh()
  print('refresh end')
end


function TunePage:detect_start(index)
  self.pitch_index = index or self.pitch_index
  -- FIXME: snap_hz will set the index to 0
  if self.pitch_index == 0 then self.pitch_index = 1 end
  self.detect_values = collections.ShiftRegister(3)
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
  -- screen.level(self.match_level)
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
  -- screen.level(self.match_level)
  if self.pitch_index == 0 then
    screen.text('-')
  else
    screen.text(self.pitch_index)
  end

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
  -- screen.rect(13, 5, 128 - 15, 32)
  screen.move(13 + 4, 5)
  screen.line_rel(-4, 0)
  screen.line_rel(0, 32)
  screen.line_rel(4, 0)

  screen.move(128 - 6, 5)
  screen.line_rel(4, 0)
  screen.line_rel(0, 32)
  screen.line_rel(-4, 0)
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
  -- inner box
  screen.rect(1, 1, 5, 5)
  screen.fill()

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
  self.actions:draw()
  -- self:draw_footer()
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
      else
        -- select action
        self.actions:selection_delta(event.delta * 0.2)
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

function TunePage:do_load_scala()
  print('do_load_scala')
end

function TunePage:do_load_tuning()
  print('do_load_tuning')
end

function TunePage:do_save_tuning()
  print('do_save_tuning')
end

--
-- module
--
return TunePage