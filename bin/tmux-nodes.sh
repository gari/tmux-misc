#!/bin/bash

if [ ${#} -eq 0 ] ; then
  echo "$(basename ${0}) srv1 srv2 ... srvN" 1>&2
  exit 1
fi

sessname="${RANDOM}"
splitmode="v"
n=1

tmux new-session -d -s ${#}-nodes -n ${sessname} '/bin/bash -l'
tmux selectw -t ${sessname}
for i in ${@} ; do
  tmux select-layout tiled >/dev/null 2>&1
  tmux send-keys -t ${#}-nodes:${sessname}.$((${n}-1)) "ssh ${i}" C-m
  if [ ${n} -lt ${#} ] ; then
    tmux split-window -${splitmode}
    if [ "${splitmode}" == "v" ] ; then
      splitmode="h"
    else
      splitmode="v"
    fi
    n=$((${n}+1))
  fi
done
tmux selectp -t top-left
tmux set-window-option -t ${#}-nodes:${sessname} synchronize-panes on
tmux -2 attach-session -d
