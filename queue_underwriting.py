#!/usr/bin/python3

import datetime
import socket
import yaml

socket_path = "/tmp/liquidsoap.sock"
sponsors_path = '/tmp/wuvt/underwriting.yml'

sponsors = yaml.safe_load(open(sponsors_path))
now = datetime.datetime.now()

if now.minute > 30:
    # get underwriting for the next hour
    now += datetime.timedelta(hours=1)

if now.weekday() in sponsors and type(sponsors[now.weekday()]) == dict and \
        now.hour in sponsors[now.weekday()]:
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
