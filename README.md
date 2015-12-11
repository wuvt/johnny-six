# johnny-six

This is the automation system for WUVT-FM powered by Liquidsoap. It schedules
all traffic (station IDs, PSAs, etc.) in compliance with FCC regulations and
supports playing different playlists depending on the day and time. It also
supports logging track metadata to the main site using the Trackman API.

The following traffic is scheduled to play at the first break after the
scheduled time:
* The station ID played at the top of the hour
* The statement of ownership played at midnight (instead of the station ID)
* Underwriting played at :00 and :30
* Public service announcements played at the :15 and :45 (or within 6 minutes)
* Promotional messages played at :30

Liner tracks are also injected roughly every 5 songs; these are intended to
remind the listener what station they are listening to and typically include
the call sign or a slogan.

## License
Copyright (c) 2015 mutantmonkey

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
