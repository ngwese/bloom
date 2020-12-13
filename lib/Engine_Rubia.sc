Engine_Rubia : CroneEngine {
  var <detector;
  var <synthGroup;
  var <fxGroup;
  // var <synth;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    var destination;

    synthGroup = Group.tail(context.xg);
    fxGroup = Group.after(synthGroup);

    SynthDef(\rubia, {
      arg out, freq;

      var snd = Klank.ar(`[[freq], nil, [1]], PinkNoise.ar(0.008!2));
      var env = Line.kr(1, 0, 2, doneAction: 2);

      snd = snd + SinOsc.ar(freq / 2, mul: 0.2);

      Out.ar(out, snd * env);
    }).add;

    context.server.sync;

    // synth controls
    this.addCommand(\start, "f", { arg msg;
      var synth = Synth.new(\rubia, [\out, context.out_b.index, \freq, msg[1]], synthGroup);
      //Post << "start[" << synth << "]\n";
    });

    // detector controls
    this.addCommand(\onset_threshold, "f", { arg msg;
      detector.setOnsetThreshold(msg[1]);
    });

    this.addCommand(\onsets_delay, "f", { arg msg;
      detector.setOnsetsDelay(msg[1]);
    });

    // start everything up
    destination = NetAddr.new("127.0.0.1", 10111); // matron
    detector = Zonsp.new(context.server, context.pitch_in_b[0].index, destination);
  }

  free {
    detector.free;
  }
}