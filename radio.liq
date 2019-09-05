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

def underwriting_request() =
    result = list.hd(default="", get_process_lines(
        "curl -sL #{playlist_api_url}/underwriting"))
    request.create(result)
end

def next_track_request() =
    result = list.hd(default="", get_process_lines(
        "curl -sL #{playlist_api_url}/next_track"))
    request.create(result)
end

def next_track_local_request() =
    result = list.hd(default="", get_process_lines(
        "python3 #{script_path}/get_track.py #{base_path}"))
    request.create(result)
end

underwriting = eat_blank(audio_to_stereo(request.dynamic(id="underwriting", underwriting_request)))

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
    if http_status == 201 then
        log("Track logged successfully")
    else
        log("Failed to log track")
    end
end

tracks_api = request.dynamic(id="tracks", next_track_request)
tracks_local = request.dynamic(id="tracks_local", next_track_local_request)

radio = eat_blank(audio_to_stereo(fallback([tracks_api, tracks_local])))
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
    ({30m0s-44m0s}, delay(4500., promo)),
    ({30m0s-44m0s}, delay(900., underwriting)),
    ({39m0s-51m0s}, delay(900., psa)),
    ({       true}, radio),
])

radio = mksafe(radio)
