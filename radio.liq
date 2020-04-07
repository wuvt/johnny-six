# WUVT Automation

%include "config.liq"

def underwriting_request() =
    result = list.hd(default="", get_process_lines(
        "curl -sL #{playlist_api_url}/underwriting"))
    if result == "" then
        system("sleep 900")
    end
    request.create(result)
end

def next_track_request() =
    result = list.hd(default="", get_process_lines(
        "curl -sL #{playlist_api_url}/next_track"))
    if result == "" then
        system("sleep 2")
    end
    request.create(result)
end

def next_track_local_request() =
    result = list.hd(default="", get_process_lines(
        "python3 #{script_path}/get_track.py #{base_path}"))
    request.create(result)
end

def prerecorded_request() =
    result = list.hd(default="", get_process_lines(
        "curl -sL #{playlist_api_url}/next_track?prerecorded=1"))
    if result == "" then
        system("sleep 2")
    end
    request.create(result)
end

def load_traffic(~id="", path) =
    eat_blank(audio_to_stereo(playlist(id=id, mode="randomize", reload=14400, path)))
end

station_id = load_traffic(id="id", "#{base_path}/playlists/id.m3u")
psa = load_traffic(id="psa", "#{base_path}/playlists/psa.m3u")
soo = load_traffic(id="soo", "#{base_path}/playlists/soo.m3u")
liner = load_traffic(id="lnr", "#{base_path}/playlists/lnr.m3u")
promo = load_traffic(id="pro", "#{base_path}/playlists/pro.m3u")

def log_metadata(m) =
    log(
        label="log_metadata",
        "Artist=#{m['artist']} Title=#{m['title']} Album=#{m['album']} Label=#{m['label']} DJ=#{m['trackman_dj_id']}")

    params = [
        ("password", trackman_password),
        ("artist", m['artist']),
        ("title", m['title']),
        ("album", m['album']),
        ("label", m['label']),
        ("dj_id", m['trackman_dj_id']),
    ]

    def encode_param(p) =
        let (k, v) = p
        y = url.encode(v)
        "#{k}=#{y}"
    end
    params = string.concat(separator="&", list.map(encode_param, params))
    request_headers = [("Content-Type", "application/x-www-form-urlencoded"),
                       ("X-Requested-With", "johnny-six")]

    http_status =
        if string.contains(prefix="https", trackman_url) then
            let ((_,http_status,_),_,_) = https.post(
                data=params,
                headers=request_headers,
                trackman_url)
            http_status
        else
            let ((_,http_status,_),_,_) = http.post(
                data=params,
                headers=request_headers,
                trackman_url)
            http_status
        end

    if http_status == 201 then
        log(label="log_metadata", "Track logged successfully")
    else
        log(label="log_metadata",  "Failed to log track")
    end
end

# create underwriting queue - if API is disabled, just leave it empty
underwriting = if playlist_api_url != "" then
    eat_blank(audio_to_stereo(request.dynamic(id="underwriting", underwriting_request)))
else
    empty(id="underwriting")
end

# build up the track queues; provide a local one and one that uses the API
tracks_local = request.dynamic(id="tracks_local", next_track_local_request)
tracks = if playlist_api_url != "" then
    fallback([request.dynamic(id="tracks", next_track_request), tracks_local])
else
    tracks_local
end

# convert tracks to stereo, strip silence at beginning and ends of tracks, log
# metadata on track change, and add liner every 4 tracks
radio = eat_blank(audio_to_stereo(tracks))
radio = on_track(log_metadata, radio)
radio = rotate(weights=[4, 1], [radio, liner])

# add an additional queue for prerecorded shows that logs everything
prerecorded = if playlist_api_url != "" then
    fallback([
        request.dynamic(id="prerecorded_api", prerecorded_request),
        request.queue(id="prerecorded")
    ])
else
    request.queue(id="prerecorded")
end
prerecorded = audio_to_stereo(prerecorded)
prerecorded = on_track(log_metadata, prerecorded)

# use external script for remote live stream auth
def remote_live_auth(user, password) =
    ret = get_process_lines("python3 #{script_path}/check_auth.py --user=#{user} --password=#{password}")
    result = list.hd(default="", ret)
    if result == "true" then
        true
    else
        false
    end
end

# add a harbor input for remote live streams
remote_live = input.harbor.ssl(id="remote_live", auth=remote_live_auth, replay_metadata=true, "remote-live")

# "johnny switch" provides our standard automation setup with automatic station
# IDs, PSAs, etc. at set times
radio = switch(id="johnny_switch", [
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

# fallback to different inputs in order
radio = fallback(id="primary_input_fallback", track_sensitive=false, [
    remote_live,
    radio,
    blank(id="safe_blank"),
])
