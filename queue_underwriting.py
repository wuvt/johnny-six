#!/usr/bin/env python3

# statements we'll need:
# find lowercase day name: `calendar.day_name[datetime.date.today().weekday()].lower()`
# compare {startdate,enddate} to today: datetime.date.today() < example[0]['underwriting'][0]['startdate']

import yaml
import datetime
import calendar
import socket
import random

underwritingSchedule = '/home/eric/sample.yml'
socketPath = "/tmp/liquidsoap.sock"

underwriters = yaml.safe_load(open(underwritingSchedule))
#thisHour = {}
thisHour = []

def push_command(url):
    cmd = "underwriting.push {}\n".format(url).encode('utf-8')
    sock = socket.socket(socket.AF_UNIX)
    sock.connect(socketPath)
    # queue the first one immediately
    sock.send(cmd)
    if datetime.datetime.now().minute > 30:
        # we must be queuing for the next hour, so add the second
        sock.send(cmd)
    sock.send(b'exit\n')

for underwriter in underwriters:
    print(underwriter['sponsor'])
    for underwriting in underwriter['underwriting']:
        if underwriting['startdate'] <= datetime.date.today() and underwriting['enddate'] >= datetime.date.today() and\
                calendar.day_name[datetime.date.today().weekday()].lower() in underwriting['schedule'] and\
                (datetime.datetime.now().hour+1) in underwriting['schedule'][calendar.day_name[datetime.date.today().weekday()].lower()]:
            print( underwriting['name'])
            if len(underwriting['url']) > 1:
                # Then we probably have multiple recordings of the grant statement
                playFile = underwriting['url'][random.randint(0,len(underwriting['url'])-1)]
            else:
                # we probably don't need this, since a random int between 0 and 0 is 0
                playFile = underwriting['url'][0]
            print(playFile)
            # probably the safer way to handle things in the future, but would require more parsing
            #thisHour[underwriting['name']] = playFile
            thisHour.append(playFile)

# because automation currently only plays one piece of underwriting at a time,
# we need arbitrate which piece we push. We'll pick a random one!
if len(thisHour) is not 0:
    push_command(thisHour[random.randint(0,len(thisHour)-1)])
    print("Underwriting for the hour queued")
else:
    print("No underwriting for the hour")
