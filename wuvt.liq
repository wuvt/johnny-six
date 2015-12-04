# WUVT Automation

set("log.file.path", "/tmp/liquidsoap.log")
set("log.stdout", true)

# TODO: these should change depending on day and time slot
# for underwriting, consider calling a script that generates an appropriate playlist
radio = playlist.safe(mode="randomize", reload=900, "/home/mutantmonkey/wuvt/automation/music.m3u")
underwriting = playlist(mode="normal", reload=900, "/home/mutantmonkey/wuvt/automation/ua.m3u")

radio = audio_to_stereo(radio)
underwriting = eat_blank(audio_to_stereo(underwriting))

def load_traffic(path) =
    eat_blank(audio_to_stereo(playlist.safe(mode="randomize", reload=900, path)))
end

station_id = load_traffic("/home/mutantmonkey/wuvt/automation/id.m3u")
psa = load_traffic("/home/mutantmonkey/wuvt/automation/psa.m3u")
soo = load_traffic("/home/mutantmonkey/wuvt/automation/soo.m3u")
liner = load_traffic("/home/mutantmonkey/wuvt/automation/lnr.m3u")
promo = load_traffic("/home/mutantmonkey/wuvt/automation/pro.m3u")

def xfade(a, b)
    add(normalize=false, [
        sequence([blank(duration=3.), fade.initial(duration=6., b)]),
        fade.final(duration=6., a)
    ])
end

def log_metadata(m) =
    title = m["title"]
    artist = m["artist"]
    album = m["album"]
    label = m["label"]

    setenv("TRACK_TITLE", title)
    setenv("TRACK_ARTIST", artist)
    setenv("TRACK_ALBUM", album)
    setenv("TRACK_LABEL", label)
    system("trackman_log.py")
end

radio = on_metadata(log_metadata, radio)

radio = random(weights=[5, 1], [radio, liner])
station_id = switch([
    ({0h0m0s-0h59m0s}, soo),
    ({          true}, station_id),
])

radio = switch(transitions=[xfade, xfade], [
    ({ 0m0s-28m0s}, delay(1800., station_id)),
    ({ 0m0s-14m0s}, delay(900., underwriting)),
    ({14m0s-28m0s}, delay(900., psa)),
    ({30m0s-44m0s}, delay(900., promo)),
    ({30m0s-44m0s}, delay(900., underwriting)),
    ({44m0s-58m0s}, delay(900., psa)),
    ({       true}, radio),
])

radio = mksafe(radio)

output.pulseaudio(radio)

# TODO: ALSA output to appropriate device (the DAC)
