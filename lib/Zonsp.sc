// https://gist.github.com/catfact/2f591c7fa2d4e89a3358875bf8133896
// onsets with pitch
Zonsp {
  var <synth;
  var <responder;
  var <destination;
  var trig_id = 0;
  var adc_channel = 0;

  *new { arg server, pitch_bus, destination;
    ^super.new.init(server, pitch_bus, destination)
  }

  init { arg server, pitch_bus, destination;
    synth = {
      arg onset_threshold=0.08,
      onsets_delay = 0;

      var hz = In.kr(pitch_bus);
      var input = SoundIn.ar(adc_channel);
      var chain = FFT(LocalBuf(512), input);
      var onsets = DelayC.kr(Onsets.kr(chain, onset_threshold, \rcomplex), maxdelaytime: 1, delaytime: onsets_delay);
      //hz.poll;
      SendTrig.kr(onsets, trig_id, hz);
    }.play(server);

    // register to receive this message
    responder = OSCFunc({ arg msg, time;
      // good old SC magic numbers
      //var id = msg[2];
      var hz = msg[3];
      // do something with hz, like calculate distance to scale entries
      // would also be a good test run for "nonperiodic polls"
      //postln('['++time++'] '++ hz);

      destination.sendMsg('/onsp', time, hz);
    },'/tr', server.addr);
  }

  setOnsetThreshold { arg threshold;
    synth.set(\onset_threshold, threshold);
  }

  setOnsetsDelay { arg delay;
    synth.set(\onsets_delay, delay);
  }

  free {
    synth.free;
    responder.free;
  }

}

/*
z = Zonsp.new(Crone.server, Crone.context.pitch_in_b[0].index,
NetAddr("127.0.0.1", 10111));
z.free;
*/