#!/usr/bin/python3

import argparse
import datetime
import os
import random
import requests
import sys

parser = argparse.ArgumentParser(
    description="Pick a track for automation to play.")
parser.add_argument('base_path')
args = parser.parse_args()

now = datetime.datetime.now()
if now.hour < 6:
    now = now.replace(hour=0, minute=0)
elif now.hour < 9:
    now = now.replace(hour=6, minute=0)
elif now.hour < 14:
    # special case for Saturday: only play children's music until 11
    if now.isoweekday() == 7 and now.hour > 11:
        now = now.replace(hour=11, minute=0)
    else:
        now = now.replace(hour=9, minute=0)
elif now.hour < 17:
    now = now.replace(hour=14, minute=0)
elif now.hour < 19:
    now = now.replace(hour=17, minute=0)
else:
    now = now.replace(hour=19, minute=0)

playlist = now.strftime("%a-%H%M")
path = os.path.join(args.base_path,
                    'playlists/default/{}.m3u'.format(playlist))

if path[0] == '/':
    if not os.path.exists(path):
        path = os.path.join(args.base_path, 'playlists/default/backup.m3u')
    with open(path) as f:
        lines = f.read().splitlines()
else:
    r = requests.get(path)
    if r.status_code != 200:
        path = os.path.join(args.base_path, 'playlists/default/backup.m3u')
        r = requests.get(path)

    if r.status_code == 200:
        lines = r.text.splitlines()
    else:
        raise FileNotFoundError(path)

# always send output to liquidsoap as UTF-8, regardless of terminal encoding
sys.stdout.buffer.write(random.choice(lines).encode('utf-8') + b'\n')
