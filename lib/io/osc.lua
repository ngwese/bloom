--
-- OSCInput
--
local OSCInput = sky.InputBase:extend()
OSCInput.OSC_EVENT = 'OSC'

local SingletonInput = nil

function OSCInput:new(props)
  OSCInput.super.new(self, props)
  -- overwrite global callback
  osc.event = function(...) self:on_osc_in(...) end
end

function OSCInput:on_osc_in(path, args, from)
  if self.chain then self.chain:process(self.mk_osc(path, args, from)) end
end

function OSCInput.mk_osc(path, args, from)
  return { type = OSCInput.OSC_EVENT, path = path, args = args, from = from }
end

function OSCInput.is_osc(event)
  return event.type == OSCInput.OSC_EVENT
end

--
-- OSCFunc
--
local OSCFunc = sky.Device:extend()

function OSCFunc:new(props)
  OSCFunc.super.new(props)
  self.path = props.path
  self.f = props.f
end

function OSCFunc:process(event, output, state)
  if OSCInput.is_osc(event) and event.path == self.path then
    if self.f then
      self.f(event.path, event.args, event.from, output)
    end
  end
end


local function shared_input(props)
  if SingletonInput == nil then
    SingletonDisplay = OSCInput(props)
  end
  return SingletonInput
end

return {
  OSCInput = shared_input,
  OSCFunc = OSCFunc,
  mk_osc = OSCInput.mk_osc,
  is_osc = OSCInput.is_osc,
  OSC_EVENT = OSCInput.OSC_EVENT,
}