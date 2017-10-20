#!/usr/bin/env python3

import yaml
import datetime
import calendar
import socket
import random

underwritingSchedule = '/tmp/sample.yml'
socketPath = "/tmp/liquidsoap.sock"

underwriters = yaml.safe_load(open(underwritingSchedule))
thisHour = []

def push_command(url):
    cmd = "underwriting.push {}\n".format(url).encode('utf-8')
    sock = socket.socket(socket.AF_UNIX)
    try:
        sock.connect(socketPath)
    except FileNotFoundError:
        print("Cannot push to socket: does not exist")
        return False
    # queue the first one immediately
    sock.send(cmd)
    if datetime.datetime.now().minute > 30:
        # we must be queuing for the next hour, so add the second
        sock.send(cmd)
    sock.send(b'exit\n')
    return True

# check which hour we're queuing for and return datetime object
def what_hour():
    queue_hour = datetime.datetime.now()
    if queue_hour.minute > 30:
        #queuing for next hour
        queue_hour = queue_hour + datetime.timedelta(hours=1)
    return queue_hour

queue_hour = what_hour()

for underwriting in underwriters:
    today=queue_hour.date()
    weekday=calendar.day_name[queue_hour.weekday()].lower()
    # we want to sanely handle do-not-kill situations
    if ( ( not underwriting['startdate'] or underwriting['startdate'] <= today ) and\
            ( not underwriting['enddate'] or underwriting['enddate'] >= today ) ) and\
            weekday in underwriting['schedule'] and queue_hour.hour in underwriting['schedule'][weekday]:
        if len(underwriting['url']) > 1:
            # Then we probably have multiple recordings of the grant statement
            playFile = underwriting['url'][random.randint(0,len(underwriting['url'])-1)]
        else:
            # we probably don't need this, since a random int between 0 and 0 is 0
            playFile = underwriting['url'][0]
        # probably the safer way to handle things in the future, but would require more parsing
        #thisHour[underwriting['name']] = playFile
        thisHour.append(playFile)

# because automation currently only plays one piece of underwriting at a time,
# we need arbitrate which piece we push. We'll pick a random one!
if len(thisHour) is not 0:
    if push_command(thisHour[random.randint(0,len(thisHour)-1)]):
        # ideally, we would list what underwriting was queued, but we're being
        # kind of sloppy with cases of overlapping underwriting
        if len(thisHour) > 1:
            print("There are {} underwriters this hour!".format(len(thisHour) ) )
        print("Underwriting for the hour queued")
    else:
        print("Failed to queue underwriting")
        exit(1)
else:
    print("No underwriting for the hour")
