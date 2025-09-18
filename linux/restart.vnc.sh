#!/usr/bin/env bash

DISPLAY_NUM=3
GEOMETRY="1600x1080"
DEPTH=24

vncserver -kill ":${DISPLAY_NUM}" || kill -9 "$(cat ~/.vnc/"$(hostname)":3.pid)"
sleep 1

[[ -e /tmp/.X11-unix/X${DISPLAY_NUM} ]] && rm -rf /tmp/.X11-unix/X${DISPLAY_NUM}
[[ -f /tmp/.X${DISPLAY_NUM}-lock     ]] && rm -rf /tmp/.X${DISPLAY_NUM}-lock
compgen -G "${HOME}"/.vnc/*:"${DISPLAY_NUM}".pid >/dev/null && rm -f "${HOME}"/.vnc/*:"${DISPLAY_NUM}".pid

vncserver -geometry "${GEOMETRY}" -depth "${DEPTH}" ":${DISPLAY_NUM}"
cat ~/.vnc/*:${DISPLAY_NUM}.pid
# vncserver -list

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
