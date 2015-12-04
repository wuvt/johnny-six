#!/usr/bin/python

import os
import requests

submit_url = "http://localhost:9090/trackman/api/automation/log"
submit_password = "hackme"

data = {
    'password': submit_password,
    'album': os.environ.get('TRACK_ALBUM', ''),
    'artist': os.environ.get('TRACK_ARTIST', ''),
    'label': os.environ.get('TRACK_LABEL', ''),
    'title': os.environ.get('TRACK_TITLE', ''),
}

r = requests.post(submit_url, data=data)
result = r.json()
if 'success' in result:
    print("Track logged successfully")
else:
    print("Failed to log track: " + result.get('error', ''))
