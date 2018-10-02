#!/bin/bash
#
# Starts a new X11 session.  This should be called by supervisor.
export DISPLAY=:0
exec /usr/bin/startx
