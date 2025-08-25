# WUVT Automation

%include "config.liq"

# UNDERWRITING API not implemented
#def underwriting_request() =
#    result = list.hd(default="", get_process_lines(
#        "curl -fsL #{playlist_api_url}/underwriting"))
#    if result == "" then
#        []
#    else
#        [request.create(result)]
#    end
#end

def next_track_request() =
    result = list.hd(default="", process.read.lines(
        "curl -fsL #{playlist_api_url}/next_track"))
    if result == "" then
        []
    else
        [request.create(result)]
    end
end

def next_track_local_request() =
    result = list.hd(default="", process.read.lines(
        "python3 #{script_path}/get_track.py #{base_path}"))
    [request.create(result)]
end

def prerecorded_request() =
    result = list.hd(default="", process.read.lines(
        "curl -fsL #{playlist_api_url}/next_track?prerecorded=1"))
    if result == "" then
        []
    else
        [request.create(result)]
    end
end

def load_traffic(~id="", path) =
    blank.eat(playlist(id=id, mode="randomize", reload=14400, path))
end

station_id = load_traffic(id="id", "#{base_path}/playlists/id.m3u")
psa = load_traffic(id="psa", "#{base_path}/playlists/psa.m3u")
soo = load_traffic(id="soo", "#{base_path}/playlists/soo.m3u")
liner = load_traffic(id="lnr", "#{base_path}/playlists/lnr.m3u")
promo = load_traffic(id="pro", "#{base_path}/playlists/pro.m3u")
tracks_backup = load_traffic(id="tracks_backup", "#{base_path}/playlists/default/backup.m3u")

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

    let http_response = http.post(
        data=params,
        headers=request_headers,
        trackman_url)

    if http_response.status_code == 201 then
        log(label="log_metadata", "Track logged successfully")
    else
        log(label="log_metadata",  "Failed to log track #{http_response}")
    end
end

# Asynchronously log metadata
#
# When johnny-six was originally implemented, I missed a very important note
# for on_track: "That function should be fast because it is executed in the
# main streaming thread."
# Wait, what? Oops!
#
# As of Liquidsoap 1.4.3, the only way to call a function asynchronously from
# on_track is to use add_timeout to create a timeout, so that's exactly what we
# do. To keep that function from being scheduled again, we return a negative
# float.
def log_metadata_async(m) =
    def log_metadata_async_call()
        log_metadata(m)
        -1.
    end
    thread.run.recurrent(fast=false, delay=0.1, log_metadata_async_call)
end

# create underwriting queue - if API is disabled, just leave it empty
#underwriting = if playlist_api_url != "" then
#    eat_blank(audio_to_stereo(request.dynamic.list(id="underwriting", retry_delay=900., underwriting_request)))
#else
#    empty(id="underwriting")
#end

underwriting = request.queue(id="underwriting")

# build up the track queues; provide a local one and one that uses the API
tracks_local = request.dynamic.list(id="tracks_local", next_track_local_request)
tracks = if playlist_api_url != "" then
    fallback([request.dynamic.list(id="tracks", retry_delay=2., next_track_request), tracks_local, tracks_backup])
else
    fallback([tracks_local, tracks_backup])
end

# convert tracks to stereo, strip silence at beginning and ends of tracks, log
# metadata on track change, and add liner every 4 tracks
radio = blank.eat(tracks)
radio.on_track(log_metadata_async)
radio = rotate(weights=[4, 1], [radio, liner])

# add an additional queue for prerecorded shows that logs everything
prerecorded = if playlist_api_url != "" then
    fallback([
        request.dynamic.list(id="prerecorded_api", retry_delay=2., prerecorded_request),
        request.queue(id="prerecorded")
    ])
else
    request.queue(id="prerecorded")
end
prerecorded.on_track(log_metadata)

# use external script for remote live stream auth
def remote_live_auth(args) =
    ret = get_process_lines("python3 #{script_path}/check_auth.py --user=#{args.user} --password=#{args.password}")
    result = list.hd(default="", ret)
    if result == "true" then
        true
    else
        false
    end
end

# add a harbor input for remote live streams
remote_live = input.harbor(
    id="remote_live",
    auth=remote_live_auth,
    replay_metadata=true,
    "remote-live"
)

# "johnny switch" provides our standard automation setup with automatic station
# IDs, PSAs, etc. at set times
radio = switch(id="johnny_switch", [
    ({0h00m-00h59m and 0m-28m}, delay(1800., soo)),
    ({1h00m-23h59m and 0m-28m}, delay(1800., station_id)),

    ({ 0m0s-14m0s}, delay(900., underwriting)),
    ({ 9m0s-21m0s}, delay(900., psa)),
    ({30m0s-44m0s}, delay(4500., promo)),
    ({30m0s-44m0s}, delay(900., underwriting)),
    ({39m0s-51m0s}, delay(900., psa)),
    ({       true}, radio),
])

# Short, simple crossfade
def transition(a, b)
    add(
        normalize=false,
        [fade.initial(duration=5., b),
         fade.final(duration=5., a)],
    )
end

# Fade the current track out and skip to the next source, skipping a track
def transition_with_skip(a, b)
    source.skip(b)
    sequence([fade.final(duration=5., a), b])
end

# When a live stream connects or a track is added to the prerecorded queue,
# immediately switch to it with a crossfade
radio = fallback(
    id="primary_input_fallback",
    track_sensitive=false,
    transitions=[transition, transition, transition_with_skip],
    [
        remote_live,
        prerecorded,
        radio,
    ],
)

# When all else fails, play silence (which will trigger an alarm later in the
# airchain)
radio = mksafe(radio)
