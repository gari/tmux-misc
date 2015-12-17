#!/bin/bash

if [ ${#} -eq 0 ] ; then
  echo "$(basename ${0}) srv1 srv2 ... srvN" 1>&2
  exit 1
fi

sessname="${$}-$(date +%Y%m%d%H%M%S)-${RANDOM}"
winname="${#}-nodes"
splitmode="v"
n=1

tmux new-session -d -s ${sessname} -n ${winname} '/bin/bash -l'
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
