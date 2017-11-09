FROM quay.io/wuvt/liquidsoap:latest

USER root

RUN apt-get update \
        && apt-get -y install python3 python3-requests \
        && rm -rf /var/lib/apt/lists/*

COPY get_track.py radio.liq wuvt.liq /usr/src/app/
COPY config_docker.liq /usr/src/app/config.liq

USER daemon

CMD ["liquidsoap", "/usr/src/app/wuvt.liq"]
