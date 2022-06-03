#!/bin/bash

# XXX - things to figure out
#   are we in tmux already or not?
#   do we have a home session or not?
#   if we're in tmux, do we have our home session or not, and are we in it or not?
#   why doesn't switch-client work when jumping from an external session to an extant home session?
#   need a usage/help function?
# XXX - mode-keys
#   emacs on some systems, or via ssh, vi on others?
#   wth?
#   need a "set-window-option -g mode-keys vi"

# we need some hostnames
if [ ${#} -eq 0 ] ; then
  echo "$(basename "${BASH_SOURCE[0]}") srv1 srv2 ... srvN" 1>&2
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
n="1"

# are we in tmux or not?
mysess=""
intmux=""
test -n "${TMUX}" && {
  intmux="0"
  mysess="$(tmux display-message -p '#S')"
}

# do we need the window or not - 0 yes, 1 no
needwin="0"

# set default shell to /bin/bash if it's not set
: ${SHELL:="/bin/bash"}
# use a (login) shell as our default new window command
: ${TMUX_NODES_SHELL:="${SHELL} -l"}
# use ssh as the default command to run
: ${TMUX_NODES_CMD:="ssh"}
TMUX_NODES_CMD="${TMUX_NODES_CMD// / Space }"
# TMUX_NODES_REMOTE_CMD has no default; cmd to run on remote hosts
: ${TMUX_NODES_REMOTE_CMD:=""}
TMUX_NODES_REMOTE_CMD="${TMUX_NODES_REMOTE_CMD// / Space }"

# we'll use a "command stream" for tmux
tmuxcmdstream=""

# we want to start a new session only if we don't have one
# otherwise attach to an existing home session
if `tmux list-sessions 2>/dev/null | grep -q "^${sessname}:"` ; then
  if [ -n "${TMUX}" ] ; then
    # XXX "switch-client" by itself does NOT work.
    # XXX have to juggle a new (detached) session with properly named window then move it.
    # XXX why?
    if [ "${mysess}" != "${sessname}" ] ; then
      tmuxcmdstream+="new-session -d -s tmp-${sessname} -n ${winname} ${TMUX_NODES_SHELL} ; "
      tmuxcmdstream+="move-window -s tmp-${sessname}:${winname} -t ${sessname} ; "
      tmuxcmdstream+="switch-client -t ${sessname} ; "
      # XXX - kill-session on temp session just in case?
      needwin="1"
    fi
  else
    tmuxcmdstream+="attach-session -t ${sessname} ; "
  fi
  # XXX - ugly
  if [ "${needwin}" -eq "0" ] ; then
    tmuxcmdstream+="new-window -n ${winname} ; "
  fi
else
  tmuxcmdstream+="new-session -d -s ${sessname} -n ${winname} ${TMUX_NODES_SHELL} ; "
  if [ -n "${TMUX}" ] ; then
    tmuxcmdstream+="switch-client -t ${sessname} ; "
  else
    tmuxcmdstream+="attach-session -t ${sessname} ; "
  fi
fi
# XXX - should these be global or not?
# need these to keep odd things from happening with renames on RHEL/CENTOS 7+
tmuxcmdstream+="set-window-option -g automatic-rename off ; "
tmuxcmdstream+="set-window-option -g allow-rename off ; "
# resize meanly
tmuxcmdstream+="set-window-option -g aggressive-resize on ; "
# renumber windows on close
tmuxcmdstream+="set -g renumber-windows on ; "
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
  tmuxcmdstream+="send-keys -t ${winpane} ${TMUX_NODES_CMD} Space ${i} Space ${TMUX_NODES_REMOTE_CMD} C-m ; "
  # alternate split modes
  if [ ${n} -lt ${#} ] ; then
    tmuxcmdstream+="split-window -t ${winpane} -${splitmode} -p 50 ${TMUX_NODES_SHELL} ; "
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
# enable clipboard
tmuxcmdstream+="set -s set-clipboard on ; "

# run our command stream
tmux -2 ${tmuxcmdstream}
