#!/usr/bin/python

import os
import requests

data = {
    'password': os.environ['TRACKMAN_PASSWORD'],
    'album': os.environ.get('TRACK_ALBUM', ''),
    'artist': os.environ.get('TRACK_ARTIST', ''),
    'label': os.environ.get('TRACK_LABEL', ''),
    'title': os.environ.get('TRACK_TITLE', ''),
}

r = requests.post(os.environ['TRACKMAN_URL'], data=data)
result = r.json()
if 'success' in result:
    print("Track logged successfully")
else:
    print("Failed to log track: " + result.get('error', ''))
