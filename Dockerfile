#FROM wuvt/liquidsoap:v1.4.3-pre-release.1
FROM savonet/liquidsoap:v1.4.3

USER root

RUN apt-get update \
        && apt-get -y install python3 python3-requests \
        && rm -rf /var/lib/apt/lists/*
RUN usermod -aG audio daemon \
        && install -d -m 0755 -o daemon -g daemon /opt/johnny-six \
        && usermod -d /opt/johnny-six daemon

COPY get_track.py radio.liq wuvt.liq /usr/src/app/
COPY config_docker.liq /usr/src/app/config.liq

WORKDIR /usr/src/app
RUN sed -i 's/server\.socket",/server.telnet",/' wuvt.liq \
        && sed -i 's/server\.socket\.path", ".*$/server.telnet.bind_addr", "0.0.0.0")/' wuvt.liq

USER daemon

CMD ["liquidsoap", "/usr/src/app/wuvt.liq"]
