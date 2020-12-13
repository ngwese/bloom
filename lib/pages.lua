sky.use('core/page')
sky.use('io/norns')

-- local json = include('lib/dep/rxi-json/json')

pitches = {174.543, 264.179, 279.629, 341.805, 389.674, 413.943, 523.817, 552.483, 693.637}

function snap_hz(hz)
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

  self.pitch_index = 1
  self.pitch_values = {}
  self.detect_values = {}
  self.detect_value = nil
  self.detect_last = nil

  self.chain = sky.Chain{
    sky.OSCFunc{
      path = '/onsp',
      f = function(path, args, from, output)
        local hz = args[2]
        -- local corrected, i = snap_hz(hz)
        -- local corrected = hz
        -- print(hz, corrected, i)
        -- engine.start(corrected)
        self:detect_refine(hz)
      end,
    },
  }
end

function TunePage:detect_start(index)
  self.pitch_index = index
  self.detect_values = {}
  self.detect_value = self.pitch_values[index]
  self.detect_last = nil
end

function TunePage:detect_stop()
  if self.detect_value then
    self.pitch_values[self.pitch_index] = self.detect_value
  end
end

function TunePage:detect_refine(pitch)
  self.detect_last = pitch
  table.insert(self.detect_values, pitch)
  table.sort(self.detect_values)
  local median_index = math.max(math.floor(#self.detect_values / 2), 1)
  self.detect_value = self.detect_values[median_index]
end

function TunePage:process(event, output, state, props)
  -- run events through the embedded chain, outputing to whatever chain this
  -- page is embeded in.
  self.chain:process(event, nil, output)
end

function TunePage:draw_bug(top_left)
  local x = top_left[1]
  local y = top_left[2]
  -- box
  screen.level(self.BUG_LO_LEVEL)
  screen.rect(x, y, 6, 7)
  screen.stroke()
  -- tuning fork
  screen.level(self.BUG_HI_LEVEL)
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

function TunePage:draw_detect(top_left)
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
  screen.text(format_num(self.detect_value, 0.01, '-'))

  -- last
  screen.move(x + 1, y + median_size / 2)
  screen.font_face(0)
  screen.font_size(8)
  screen.level(self.DETECT_LEVEL)
  screen.text('> ' .. format_num(self.detect_last, 0.01))
end

function TunePage:draw(event, props)
  self:draw_detect({10, 20})
  self:draw_bug({128 - 7, 64 - 7})
  -- print(sky.to_string(event))
end


--
-- Controller
--

local Controller = sky.Object:extend()

function Controller:new(model)
  self.model = model
end

function Controller:add_params()
  params:add_separator('palo')
end

--
-- module
--
return {
  TunePage = TunePage,
  Controller = Controller,
}