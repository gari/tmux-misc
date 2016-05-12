#!/bin/bash

# XXX - run "bash -l" by default, use "getent" or something similar to get user's shell (or environment var)
# XXX - runs "ssh ..." by default, might need options passed (or environment var)
# XXX - probably want to pick a static, normal tmux session name, like "tmux-nodes" and use -A/-D to create/attach/detach; always use that as our "home" session
# XXX - probably want to check for $TMUX environment var
# XXX - pane names might be set to passed name/IP of SSH hosts(? probably not, given length, ., etc.)

# XXX - things to figure out
#   are we in tmux already or not?
#   do we have a home session or not?
#   if we're in tmux, do we have our home session or not, and are we in it or not?

# we need some hostnames
if [ ${#} -eq 0 ] ; then
  echo "$(basename ${0}) srv1 srv2 ... srvN" 1>&2
  exit 1
fi

# our "home" session is called tmux-nodes
sessname="tmux-nodes"
# windows are named with PID-DATE-#NODES
winname="${$}-$(date +%Y%m%d%H%M%S)-${#}nodes"
# and a nice name for session+window
sesswin="${sessname}:${winname}"

# alternate between veritcal and horizontal split mode
splitmode="v"

# pane counter
n=1

# are we in tmux or not?
mysess=""
intmux=""
test -n "${TMUX}" && {
  intmux="0"
  mysess="$(tmux display-message -p '#S')"
}

# we'll use a "command stream" for tmux
tmuxcmdstream=""

# we want to start a new session only if we don't have one
# otherwise attach to an existing home session
if `tmux list-sessions 2>/dev/null | grep -q "^${sessname}:"` ; then
  if [ -n "${TMUX}" ] ; then
    if [ "${mysess}" != "${sessname}" ] ; then
      tmuxcmdstream+="switch-client -t ${sessname} ; "
    fi
  else
    tmuxcmdstream+="attach-session -t ${sessname} ; "
  fi
  tmuxcmdstream+="new-window -n ${winname} ; "
else
  tmuxcmdstream+="new-session -d -s ${sessname} -n ${winname} /bin/bash -l ; "
  if [ -n "${TMUX}" ] ; then
    tmuxcmdstream+="switch-client -t ${sessname} ; "
  else
    tmuxcmdstream+="attach-session -t ${sessname} ; "
  fi
fi
# need these to keep odd things from happening with renames on RHEL/CENTOS 7+
tmuxcmdstream+="set-window-option -g automatic-rename off ; "
tmuxcmdstream+="set-window-option -g allow-rename off ; "
# resize meanly
tmuxcmdstream+="set-window-option -g aggressive-resize on ; "
# select our new window
tmuxcmdstream+="select-window -t ${sesswin} ; "
# iterate through each name passed as an SSH hostname
for i in ${@} ; do
  # pane names are 0..${#}
  panename="$((${n}-1))"
  # window+pane
  winpane="${sesswin}.${panename}"
  # resize to 80x24
  tmuxcmdstream+="resize-pane -t ${winpane} -x 80 -y 24 ; "
  # retile every trip through, then send SSH command
  tmuxcmdstream+="select-layout -t ${sesswin} tiled ; "
  # XXX - send-keys needs either either quotation or "Space" here - this works 100%
  tmuxcmdstream+="send-keys -t ${winpane} ssh Space ${i} C-m ; "
  # alternate split modes
  if [ ${n} -lt ${#} ] ; then
    tmuxcmdstream+="split-window -t ${winpane} -${splitmode} -p 50 ; "
    if [ "${splitmode}" == "v" ] ; then
      splitmode="h"
    else
      splitmode="v"
    fi
    n=$((${n}+1))
  fi
done
# select first pane of our new window
tmuxcmdstream+="select-pane -t ${sesswin}.0 ; "
# synchronize panes
tmuxcmdstream+="set-window-option -t ${sesswin} synchronize-panes on ; "
# run it
env TMUX='' tmux -2 ${tmuxcmdstream}
