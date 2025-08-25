# WUVT Automation

settings.log.file := false
settings.log.stdout := true

settings.server.socket := true
settings.server.socket.path := "/tmp/liquidsoap.sock"

settings.scheduler.fast_queues := 1
settings.scheduler.generic_queues := 6

%include "radio.liq"

alsa_output = environment.get("ALSA_OUTPUT")
if alsa_output == "" then
    output.pulseaudio(radio)
else
    output.alsa(device=alsa_output, radio)
end
