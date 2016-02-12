import os
import urllib.parse
from datetime import datetime

import config


class playlist():
    def __init__(self, filename):
        self.filename = filename
        self.basename = os.path.basename(filename)
        base = self.basename.split('-')
        if len(base) != 2:
            raise Exception("Filename in the wrong format.")
        self.airdate = datetime.strptime(base[0], "%Y%m%d")
        self.period = base[1].split('.')[0].lower()
        if self.period not in config.PERIOD_SCHED.keys():
            raise Exception("Filename period not valid.")

    def validate(self):
        """ No validation done here yet """
        # Should validate tracks as well
        pass

    def get_tracks(self):
        with open(self.filename, 'r') as f:
            for line in f.readlines():
                if line[0] == '#':
                    continue
                if line[-1] == '\n':
                    line = line[:-1]
                yield track(line)

    def translate_filename(self):
        return "{0}-{1}.m3u".format(self.airdate.strftime("%a")[0:3],
                                    config.PERIOD_SCHED[self.period])

    def translate(self, f):
        """ f is an open file to the destination """
        for track in self.get_tracks():
            f.write(track.translate() + '\n')

class track():
    def __init__(self, path):
        self.path = path

    def translate(self):
        basename = config.BASENAME_PATTERN.match(self.path)
        if basename != None:
            return config.TRANSLATE_URL + urllib.parse.quote(basename.group(1))
        else:
            # A failure
            pass

    def validate(self):
        """ No validation done here yet """
        pass
