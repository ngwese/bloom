
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

return Controller