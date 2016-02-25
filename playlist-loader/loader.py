#!/usr/bin/env python
import os
import datetime
import shutil
import socket

import config
import playlist


def find_playlists(directory):
    files = os.listdir(directory)
    return filter(lambda x: x[-4:] == ".m3u", files)


def update_playlist(playlist_file):
    name = playlist_file[:-4]
    liq_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    liq_sock.settimeout(60.0)
    liq_sock.connect(config.LIQUIDSOAP_SOCK)
    liq_sock.sendall("reload_custom {0}\r\n".format(name).encode("utf-8"))
    rec = liq_sock.recv(256)
    if "END" not in rec.decode("utf-8"):
        rec = liq_sock.recv(256)
    # Make sure we get the "END" command
    liq_sock.sendall("quit\r\n".encode("utf-8"))
    rec = liq_sock.recv(256)
    # Get the bye! ack
    liq_sock.shutdown(socket.SHUT_RDWR)
    liq_sock.close()


def round_to_schedule(time):
    for _, v in config.PERIOD_SCHED.iteritems():
        if time > v:
            return v


def main():
    # Remove old playlists
    active_playlists = find_playlists(config.DEST)
    for playlist_file in active_playlists:
        mtime = datetime.datetime.fromtimestamp(
                os.path.getmtime(os.path.join(config.DEST, playlist_file)))
        if mtime < datetime.datetime.now() - datetime.timedelta(days=6):
            os.unlink(os.path.join(config.DEST, playlist_file))

    # Move new playlists into place
    playlists = find_playlists(config.STAGING)
    for playlist_file in playlists:
        p = playlist.playlist(os.path.join(config.STAGING, playlist_file))
        if p.airdate < datetime.datetime.now():
            # I should probably delete this
            continue
        if p.airdate > datetime.datetime.now() + datetime.timedelta(days=5.5):
            continue
        # p.airdate within 6 days from now
        if p.validate():
            # Archive the playlist
            shutil.copyfile(p.filename, os.path.join(
                            config.ARCHIVE, p.basename))
            with open(os.path.join(config.DEST,
                                   p.translate_filename()), "w+") as f:
                p.translate(f)
            # Delete the old file
            os.unlink(os.path.join(p.filename))
            # TODO: Trigger a reload of this playlist config.LIQUIDSOAP_SOCK
            update_playlist(p.translate_filename())
        else:
            print("Playlist failed to validate")
            # Error handling goes here
            pass

if __name__ == '__main__':
    main()
