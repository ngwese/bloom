include('sky/unstable')
sky.use('device/make_note')
sky.use('device/transform')
sky.use('io/norns')

local lsys = include('lib/dep/lua-lsys/lsys')
local devices = include('lib/devices')
tu = require('tabutil')

ng = devices.NoteGesture{
  debug = true,
}

main = sky.Chain{
  ng,
  sky.Logger{ bypass = true },
}

input = sky.Input{
  chain = main,
}

--
-- script logic
--

function init()
end

