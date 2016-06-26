# WUVT Automation

%include "config.liq"

custom_reloaders = ref [("",fun(~uri="")->())]

def reload_custom(name) =
    def find_and_reload(x) =
        if name == fst(x) then
            reloader = snd(x)
            reloader()
        end
    end

    list.iter(find_and_reload, !custom_reloaders)
    "OK"
end
server.register(description="Reload the specified custom playlist.",
                usage="reload_custom <name>", "reload_custom", reload_custom)

def load_playlist(name) =
    s = playlist.reloadable(id="custom_#{name}",
                            "#{base_path}/playlists/active/#{name}.m3u")
    custom_reloaders := list.add((name, fst(s)), !custom_reloaders)
    eat_blank(audio_to_stereo(snd(s)))
end

def dynamic_request() =
    result = list.hd(get_process_lines(
        "python3 #{script_path}/get_track.py #{base_path}"))
    request.create(result)
end

radio = switch(id="normal", [
    # Monday
    ({1w and  0h- 5h59m59s}, load_playlist('Mon-0000')),
    ({1w and  6h- 8h59m59s}, load_playlist('Mon-0600')),
    ({1w and  9h-13h59m59s}, load_playlist('Mon-0900')),
    ({1w and 14h-16h59m59s}, load_playlist('Mon-1400')),
    ({1w and 17h-18h59m59s}, load_playlist('Mon-1700')),
    ({1w and 19h-23h59m59s}, load_playlist('Mon-1900')),

    # Tuesday
    ({2w and  0h- 5h59m59s}, load_playlist('Tue-0000')),
    ({2w and  6h- 8h59m59s}, load_playlist('Tue-0600')),
    ({2w and  9h-13h59m59s}, load_playlist('Tue-0900')),
    ({2w and 14h-16h59m59s}, load_playlist('Tue-1400')),
    ({2w and 17h-18h59m59s}, load_playlist('Tue-1700')),
    ({2w and 19h-23h59m59s}, load_playlist('Tue-1900')),

    # Wednesday
    ({3w and  0h- 5h59m59s}, load_playlist('Wed-0000')),
    ({3w and  6h- 8h59m59s}, load_playlist('Wed-0600')),
    ({3w and  9h-13h59m59s}, load_playlist('Wed-0900')),
    ({3w and 14h-16h59m59s}, load_playlist('Wed-1400')),
    ({3w and 17h-18h59m59s}, load_playlist('Wed-1700')),
    ({3w and 19h-23h59m59s}, load_playlist('Wed-1900')),

    # Thursday
    ({4w and  0h- 5h59m59s}, load_playlist('Thu-0000')),
    ({4w and  6h- 8h59m59s}, load_playlist('Thu-0600')),
    ({4w and  9h-13h59m59s}, load_playlist('Thu-0900')),
    ({4w and 14h-16h59m59s}, load_playlist('Thu-1400')),
    ({4w and 17h-18h59m59s}, load_playlist('Thu-1700')),
    ({4w and 19h-23h59m59s}, load_playlist('Thu-1900')),

    # Friday
    ({5w and  0h- 5h59m59s}, load_playlist('Fri-0000')),
    ({5w and  6h- 8h59m59s}, load_playlist('Fri-0600')),
    ({5w and  9h-13h59m59s}, load_playlist('Fri-0900')),
    ({5w and 14h-16h59m59s}, load_playlist('Fri-1400')),
    ({5w and 17h-18h59m59s}, load_playlist('Fri-1700')),
    ({5w and 19h-23h59m59s}, load_playlist('Fri-1900')),

    # Saturday
    ({6w and  0h- 5h59m59s}, load_playlist('Sat-0000')),
    ({6w and  6h- 8h59m59s}, load_playlist('Sat-0600')),
    ({6w and  9h-13h59m59s}, load_playlist('Sat-0900')),
    ({6w and 14h-16h59m59s}, load_playlist('Sat-1400')),
    ({6w and 17h-18h59m59s}, load_playlist('Sat-1700')),
    ({6w and 19h-23h59m59s}, load_playlist('Sat-1900')),

    # Sunday
    ({7w and  0h- 5h59m59s}, load_playlist('Sun-0000')),
    ({7w and  6h- 8h59m59s}, load_playlist('Sun-0600')),
    ({7w and  9h-13h59m59s}, load_playlist('Sun-0900')),
    ({7w and 14h-16h59m59s}, load_playlist('Sun-1400')),
    ({7w and 17h-18h59m59s}, load_playlist('Sun-1700')),
    ({7w and 19h-23h59m59s}, load_playlist('Sun-1900')),

    ({                 true},
        eat_blank(audio_to_stereo(request.dynamic(id="dynamic",
                                                  dynamic_request)))),
])

# underwriting is queued by an external script
# because underwriting depends on the hour, we need to ensure that it doesn't
# queue something up ahead of time that will be for the wrong hour
underwriting = eat_blank(audio_to_stereo(request.queue(id="underwriting")))

def load_traffic(~id="", path) =
    eat_blank(audio_to_stereo(playlist(id=id, mode="randomize", reload=14400, path)))
end

station_id = load_traffic(id="id", "#{base_path}/playlists/id.m3u")
psa = load_traffic(id="psa", "#{base_path}/playlists/psa.m3u")
soo = load_traffic(id="soo", "#{base_path}/playlists/soo.m3u")
liner = load_traffic(id="lnr", "#{base_path}/playlists/lnr.m3u")
promo = load_traffic(id="pro", "#{base_path}/playlists/pro.m3u")

def log_metadata(m) =
    log("Artist=#{m['artist']} Title=#{m['title']} Album=#{m['album']} Label=#{m['label']}")

    password = url.encode(trackman_password)
    title = url.encode(m["title"])
    artist = url.encode(m["artist"])
    album = url.encode(m["album"])
    label = url.encode(m["label"])

    server = http.post(data="password=#{password}&title=#{title}&artist=#{artist}&album=#{album}&label=#{label}",
                       headers=[("Content-Type", "application/x-www-form-urlencoded"),
                                ("X-Requested-With", "johnny-six")],
                       trackman_url)
    http_status = snd(fst(fst(fst(server))))
    if http_status == 200 then
        log("Track logged successfully")
    else
        log("Failed to log track")
    end
end

radio = on_track(log_metadata, radio)
radio = rotate(weights=[4, 1], [radio, liner])

# add an additional queue for prerecorded shows that logs everything
prerecorded = eat_blank(audio_to_stereo(request.queue(id="prerecorded")))
prerecorded = on_track(log_metadata, prerecorded)

radio = switch([
    ({       true}, prerecorded),

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
