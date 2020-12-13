engine.name = 'Rubia'

include('sky/unstable')
sky.use('io/norns')
sky.use('lib/io/osc')

pages = include('lib/pages')

logger = sky.Logger{}

ui = sky.PageRouter{
  initial = 'tune',
  pages = {
    tune = pages.TunePage()
  }
}

display = sky.Chain{
  sky.NornsDisplay{
    screen.clear,
    ui:draw_router(),
    screen.update,
  }
}

osc_input = sky.OSCInput{
  chain = sky.Chain{
    sky.Logger{},
    ui:event_router(),
  }
}

norns_input = sky.NornsInput{
  chain = sky.Chain{
    logger,
  }
}

redraw_id = nil

function init()
  engine.onset_threshold(0.12) -- handpan (with contact mic)
  engine.onset_threshold(1.8)  -- kalimba
  engine.onsets_delay(0.02)

  -- TODO: add this abstraction to sky/process.lua
  redraw_id = clock.run(function()
    local interval = 1.0 / 15 -- 15 FPS redraw
    while true do
      display:process(sky.mk_redraw())
      clock.sleep(interval)
    end
  end)
end

function cleanup()
  -- TODO: package in sky/process.lua
  clock.cancel(redraw_id)
end