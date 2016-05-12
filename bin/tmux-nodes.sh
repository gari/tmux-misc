#!/bin/bash

if [ ${#} -eq 0 ] ; then
  echo "$(basename ${0}) srv1 srv2 ... srvN" 1>&2
  exit 1
fi

# XXX - run "bash -l" by default, use "getent" or something similar to get user's shell (or environment var)
# XXX - runs "ssh ..." by default, might need options passed (or environment var)
# XXX - probably want to pick a static, normal tmux session name, like "tmux-nodes" and use -A/-D to create/attach/detach; always use that as our "home" session
# XXX - probably want to check for $TMUX environment var
# XXX - pane names might be set to passed name/IP of SSH hosts(? probably not, given length, ., etc.)

# use PID, date/timestamp and a random number for session and window name(s)
sessname="${$}-$(date +%Y%m%d%H%M%S)-${RANDOM}"
winname="${$}-${#}-nodes"

# split mode alternates between v and h
splitmode="v"

# counter for pane name
n=1

tmux list-sessions >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  # if we don't have a session, create one
  tmux new-session -d -s ${sessname} -n ${winname} '/bin/bash -l'
else
  # otherwise just use the first session name
  sessname="$(tmux list-sessions | head -1 | cut -f1 -d:)"
  tmux new-window -d -n ${winname} '/bin/bash -l'
fi
tmux set-window-option -g automatic-rename off
tmux set-window-option -g allow-rename off
tmux select-window -t ${sessname}:${winname}
for i in ${@} ; do
  panename="$((${n}-1))"
  tmux select-layout -t ${sessname}:${winname} tiled >/dev/null 2>&1
  tmux send-keys -t ${sessname}:${winname}.${panename} "ssh ${i}" C-m
  if [ ${n} -lt ${#} ] ; then
    tmux split-window -t ${sessname}:${winname}.${panename} -${splitmode} -p 50
    if [ "${splitmode}" == "v" ] ; then
      splitmode="h"
    else
      splitmode="v"
    fi
    n=$((${n}+1))
  fi
done
tmux select-pane -t top-left
tmux set-window-option -t ${sessname}:${winname} synchronize-panes on
tmux -2 attach-session -d -t ${sessname}
