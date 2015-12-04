#!/usr/bin/python3

import os
import requests

data = {
    'password': os.environ['TRACKMAN_PASSWORD'],
    'album': os.environb.get(b'TRACK_ALBUM', b'').decode('utf-8'),
    'artist': os.environb.get(b'TRACK_ARTIST', b'').decode('utf-8'),
    'label': os.environb.get(b'TRACK_LABEL', b'').decode('utf-8'),
    'title': os.environb.get(b'TRACK_TITLE', b'').decode('utf-8'),
}

r = requests.post(os.environ['TRACKMAN_URL'], data=data)
result = r.json()
if 'success' in result:
    print("Track logged successfully")
else:
    print("Failed to log track: " + result.get('error', ''))
