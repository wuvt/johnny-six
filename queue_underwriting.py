#!/usr/bin/python3

import datetime
import random
import socket

# TODO: keep a mapping of hours to sponsors and use that instead of picking
# randomly

choices = [
    "/home/mutantmonkey/wuvt/automation/ua/mm.wav",
    "/home/mutantmonkey/wuvt/automation/ua/UA - Greenhouse.mp3",
    "/home/mutantmonkey/wuvt/automation/ua/UA - The Cellar.mp3",
]

now = datetime.datetime.now()

sock = socket.socket(socket.AF_UNIX)
sock.connect('/tmp/liquidsoap.sock')

choice = random.choice(choices)
cmd = "underwriting.push {}\n".format(choice).encode('utf-8')

# queue a first one immediately
sock.send(cmd)

if now.minute > 30:
    # we must be queuing for the next hour, so add another
    sock.send(cmd)

sock.send(b'exit\n')
