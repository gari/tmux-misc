#!/bin/bash

env TMUX_NODES_CMD="" "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/tmux-nodes.sh" ""
