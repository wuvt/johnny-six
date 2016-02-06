# WUVT Automation

%include "config.liq"

backup = mksafe(playlist(mode="randomize", reload=86400, "#{base_path}/playlists/default/backup.m3u"))

def load_playlist(name) =
    custom = playlist.once("#{base_path}/playlists/#{name}.m3u")
    randomized = playlist(mode="randomize", reload=86400, "#{base_path}/playlists/default/#{name}.m3u")
    eat_blank(audio_to_stereo(fallback([custom, randomized, backup])))
end

radio = switch([
    # Monday
    ({1w and  0h- 5h59m59s}, load_playlist('OVR_MON')),
    ({1w and  6h- 8h59m59s}, load_playlist('MRN_MON')),
    ({1w and  9h-13h59m59s}, load_playlist('MID_MON')),
    ({1w and 14h-16h59m59s}, load_playlist('AFT_MON')),
    ({1w and 17h-18h59m59s}, load_playlist('JAZZ_MON')),
    ({1w and 19h-23h59m59s}, load_playlist('EVE_MON')),

    # Tuesday
    ({2w and  0h- 5h59m59s}, load_playlist('OVR_TUE')),
    ({2w and  6h- 8h59m59s}, load_playlist('MRN_TUE')),
    ({2w and  9h-13h59m59s}, load_playlist('MID_TUE')),
    ({2w and 14h-16h59m59s}, load_playlist('AFT_TUE')),
    ({2w and 17h-18h59m59s}, load_playlist('JAZZ_TUE')),
    ({2w and 19h-23h59m59s}, load_playlist('EVE_TUE')),

    # Wednesday
    ({3w and  0h- 5h59m59s}, load_playlist('OVR_WED')),
    ({3w and  6h- 8h59m59s}, load_playlist('MRN_WED')),
    ({3w and  9h-13h59m59s}, load_playlist('MID_WED')),
    ({3w and 14h-16h59m59s}, load_playlist('AFT_WED')),
    ({3w and 17h-18h59m59s}, load_playlist('JAZZ_WED')),
    ({3w and 19h-23h59m59s}, load_playlist('EVE_WED')),

    # Thursday
    ({4w and  0h- 5h59m59s}, load_playlist('OVR_THU')),
    ({4w and  6h- 8h59m59s}, load_playlist('MRN_THU')),
    ({4w and  9h-13h59m59s}, load_playlist('MID_THU')),
    ({4w and 14h-16h59m59s}, load_playlist('AFT_THU')),
    ({4w and 17h-18h59m59s}, load_playlist('JAZZ_THU')),
    ({4w and 19h-23h59m59s}, load_playlist('EVE_THU')),

    # Friday
    ({5w and  0h- 5h59m59s}, load_playlist('OVR_FRI')),
    ({5w and  6h- 8h59m59s}, load_playlist('MRN_FRI')),
    ({5w and  9h-13h59m59s}, load_playlist('MID_FRI')),
    ({5w and 14h-16h59m59s}, load_playlist('AFT_FRI')),
    ({5w and 17h-18h59m59s}, load_playlist('JAZZ_FRI')),
    ({5w and 19h-23h59m59s}, load_playlist('EVE_FRI')),

    # Saturday
    ({6w and  0h- 5h59m59s}, load_playlist('OVR_SAT')),
    ({6w and  6h- 8h59m59s}, load_playlist('MRN_SAT')),
    ({6w and  9h-13h59m59s}, load_playlist('MID_SAT')),
    ({6w and 14h-16h59m59s}, load_playlist('AFT_SAT')),
    ({6w and 17h-18h59m59s}, load_playlist('JAZZ_SAT')),
    ({6w and 19h-23h59m59s}, load_playlist('EVE_SAT')),

    # Sunday
    ({7w and  0h- 5h59m59s}, load_playlist('OVR_SUN')),
    ({7w and  6h- 8h59m59s}, load_playlist('MRN_SUN')),
    ({7w and  9h-13h59m59s}, load_playlist('MID_SUN')),
    ({7w and 14h-16h59m59s}, load_playlist('AFT_SUN')),
    ({7w and 17h-18h59m59s}, load_playlist('JAZZ_SUN')),
    ({7w and 19h-23h59m59s}, load_playlist('EVE_SUN')),
])

# underwriting is queued by an external script
# because underwriting depends on the hour, we need to ensure that it doesn't
# queue something up ahead of time that will be for the wrong hour
underwriting = eat_blank(audio_to_stereo(request.queue(id="underwriting")))

def load_traffic(path) =
    eat_blank(audio_to_stereo(playlist(mode="randomize", reload=14400, path)))
end

station_id = load_traffic("#{base_path}/playlists/id.m3u")
psa = load_traffic("#{base_path}/playlists/psa.m3u")
soo = load_traffic("#{base_path}/playlists/soo.m3u")
liner = load_traffic("#{base_path}/playlists/lnr.m3u")
promo = load_traffic("#{base_path}/playlists/pro.m3u")

def log_metadata(m) =
    title = m["title"]
    artist = m["artist"]
    album = m["album"]
    label = m["label"]

    setenv("TRACKMAN_URL", trackman_url)
    setenv("TRACKMAN_PASSWORD", trackman_password)
    setenv("TRACK_TITLE", title)
    setenv("TRACK_ARTIST", artist)
    setenv("TRACK_ALBUM", album)
    setenv("TRACK_LABEL", label)
    system("trackman_log.py")
end

radio = on_track(log_metadata, radio)
radio = rotate(weights=[4, 1], [radio, liner])

radio = switch([
    ({0h00m-00h59m and 0m-28m}, delay(1800., soo)),
    ({1h00m-23h59m and 0m-28m}, delay(1800., station_id)),

    ({ 0m0s-14m0s}, delay(900., underwriting)),
    ({ 9m0s-21m0s}, delay(900., psa)),
    ({30m0s-44m0s}, delay(900., promo)),
    ({30m0s-44m0s}, delay(900., underwriting)),
    ({39m0s-51m0s}, delay(900., psa)),
    ({       true}, radio),
])

radio = mksafe(radio)

output.pulseaudio(radio)
