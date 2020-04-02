# WUVT Automation

set("log.file", false)
set("log.stdout", true)

set("server.socket", true)
set("server.socket.path", "/tmp/liquidsoap.sock")

set("scheduler.fast_queues", 1)
set("scheduler.generic_queues", 6)

%include "radio.liq"

alsa_output = getenv("ALSA_OUTPUT")
if alsa_output == "" then
    output.pulseaudio(radio)
else
    output.alsa(device=alsa_output, radio)
end
