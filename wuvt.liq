# WUVT Automation

set("log.file.path", "/tmp/liquidsoap.log")
set("log.stdout", true)

# TODO: these should change depending on day and time slot
radio = playlist(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/music.m3u")
underwriting = playlist(mode="normal", reload=900, "/home/mutantmonkey/wuvt/automation/ua.m3u")

station_id = playlist(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/id.m3u")
psa = playlist(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/psa.m3u")
soo = playlist(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/soo.m3u")
liner = playlist(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/lnr.m3u")
promo = playlist(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/pro.m3u")

def xfade(a, b)
    add(normalize=false, [
        sequence([blank(duration=3.), fade.initial(duration=6., b)]),
        fade.final(duration=6., a)
    ])
end

radio = audio_to_stereo(radio)
underwriting = audio_to_stereo(underwriting)
station_id = audio_to_stereo(station_id)
psa = audio_to_stereo(psa)
soo = audio_to_stereo(soo)
liner = audio_to_stereo(liner)
promo = audio_to_stereo(promo)

radio = random(weights=[5, 1], [radio, liner])
station_id = switch([
    ({0h0m0s-0h59m0s}, soo),
    ({          true}, station_id),
])

radio = switch(transitions=[xfade, xfade], [
    ({ 0m0s-28m0s}, delay(1800., station_id)),
    ({ 0m0s-28m0s}, delay(900., underwriting)),
    ({14m0s-28m0s}, delay(900., psa)),
    ({30m0s-44m0s}, delay(900., promo)),
    ({30m0s-58m0s}, delay(900., underwriting)),
    ({44m0s-58m0s}, delay(900., psa)),
    ({       true}, radio),
])

radio = mksafe(radio)

# TODO: ship metadata to site using an on_metadata thing
# easiest way is probably to use an external script
# see http://liquidsoap.fm/doc-svn/radiopi.html and http://liquidsoap.fm/doc-svn/dolebrai.html
#on_metadata(fun (meta) ->
#   use meta["artist"] etc.
#, radio)

output.pulseaudio(radio)

# TODO: ALSA output to appropriate device (the DAC)
