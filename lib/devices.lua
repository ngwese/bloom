local Deque = require('container/deque')

local NoteGesture = sky.Device:extend()
NoteGesture.INTERVALS = 'NG_INTERVALS'
NoteGesture.ONSETS = 'NG_ONSETS'
NoteGesture.DURATIONS = 'NG_DURATIONS'
NoteGesture.RESET = 'NG_RESET'

function NoteGesture:new(props)
  self.debug = props.debug or false
  self.depth = props.depth or 4

  self._notes = Deque.new()
  self._intervals = Deque.new()
  self._onsets = Deque.new()
  self._durations = Deque.new()
end

function NoteGesture:mk_intervals()
  return {
    type = NoteGesture.INTERVALS,
    values = self._intervals:to_array(),
  }
end

function NoteGesture.eq_correlation(event, correlation)
  return event.correlation == correlation
end

function NoteGesture:process(event, output)
  if sky.is_type(event, sky.types.NOTE_ON) then
    local now = clock.get_beats()
    local e = sky.copy(event)
    e.beat = now

    -- capture interval
    local last = self._notes:peek()
    if last then
      self._intervals:push_back(e.note - last.note)
      if self._intervals:count() > self.depth then self._intervals:pop() end
      if self.debug then
        local v = table.concat(self._intervals:to_array(), ' ')
        print("<< INTERVALS: " .. v .. " >>")
      end
      output(self:mk_intervals())
    end

    -- -- capture onset
    -- last = self._onsets:peek_back()
    -- if last then
    --   self._onsets:push_back(now - last)
    -- else
    --   self._onsets:push_back(0)
    -- end
    -- if self._onsets:count() > self.depth then self._onsets:pop() end
    -- if self.debug then
    --   local v = table.concat(self._onsets:to_array(), ' ')
    --   print("<< ONSETS: " .. v .. " >>")
    -- end



    -- record
    self._notes:push(e)
    if self._notes:count() > self.depth then
      self._notes:pop_back()
    end

  elseif sky.is_type(event, sky.types.NOTE_OFF) then
    local now = clock.get_beats()
    local prior = self._notes:find(event.correlation, self.eq_correlation)
    if prior then
      self._durations:push_back(now - prior.beat)
      if self._durations:count() > self.depth then self._durations:pop() end
      if self.debug then
        local v = table.concat(self._durations:to_array(), ' ')
        print("<< DURATIONS: " .. v .. " >>")
      end

    end
  end
  output(event)
end

return {
  NoteGesture = NoteGesture,
}