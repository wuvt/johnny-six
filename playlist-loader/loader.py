#!/usr/bin/env python
import os
import datetime
import shutil

import config
import playlist

def find_playlists(directory):
    files = os.listdir(directory)
    return filter(lambda x: x[-4:] == ".m3u", files)

def main():
    playlists = find_playlists(config.STAGING)
    for playlist_file in playlists:
        p = playlist.playlist(os.path.join(config.STAGING, playlist_file))
        if p.airdate < datetime.datetime.now():
            #os.unlink(os.path.join(config.STAGING, p.filename))
            continue
        if p.airdate > datetime.datetime.now() + datetime.timedelta(days=6):
            continue
        with open(os.path.join(config.DEST, p.translate_filename()), "w+") as f:
            p.translate(f)
        shutil.copyfile(p.filename,
                        os.path.join(config.ARCHIVE, p.basename))
        # Delete the old file
        os.unlink(os.path.join(p.filename))

if __name__ == '__main__':
    main()
