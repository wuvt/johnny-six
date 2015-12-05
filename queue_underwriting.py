#!/usr/bin/python3

import datetime
import socket

socket_path = "/tmp/liquidsoap.sock"
sponsors = {
    # Monday
    0: {
    },

    # Tuesday
    1: {
    },

    # Wednesday
    2: {
    },

    # Thursday
    3: {
    },

    # Friday
    4: {
    },

    # Saturday
    5: {
        0: "/home/mutantmonkey/wuvt/automation/ua/mm.wav",
    },

    # Sunday
    6: {
    },
}

now = datetime.datetime.now()

if now.minute > 30:
    # get underwriting for the next hour
    now += datetime.timedelta(hours=1)

if now.hour in sponsors[now.weekday()]:
    sponsor = sponsors[now.weekday()][now.hour]
    cmd = "underwriting.push {}\n".format(sponsor).encode('utf-8')

    sock = socket.socket(socket.AF_UNIX)
    sock.connect(socket_path)

    # queue the first one immediately
    sock.send(cmd)

    if now.minute > 30:
        # we must be queuing for the next hour, so add the second
        sock.send(cmd)

    sock.send(b'exit\n')

    print("Underwriting queued")
else:
    print("No underwriting to queue for {}".format(now))
