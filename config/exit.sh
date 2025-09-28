#!/usr/bin/env bash
# bye_minimal.sh - simple goodbye frame

FRAME_W=79
FRAME_H=24
MSG="Goodbye Y'all!"

trap 'cleanup' INT TERM EXIT

cleanup(){
  tput cnorm
  tput sgr0
  clear
  exit 0
}

# terminal size
cols=$(tput cols)
lines=$(tput lines)

if [ "$cols" -ge "$FRAME_W" ] && [ "$lines" -ge "$FRAME_H" ]; then
  START_COL=$(( (cols - FRAME_W) / 2 ))
  START_ROW=$(( (lines - FRAME_H) / 2 ))
else
  START_COL=0
  START_ROW=0
fi

cup() {
  local r=$1; local c=$2
  tput cup $((START_ROW + r)) $((START_COL + c))
}

draw_frame(){
  # top
  cup 0 0
  printf '+'
  for ((i=1;i<FRAME_W-1;i++)); do printf '-'; done
  printf '+'

  # sides
  for ((r=1;r<FRAME_H-1;r++)); do
    cup $r 0; printf '|'
    cup $r $((FRAME_W-1)); printf '|'
  done

  # bottom
  cup $((FRAME_H-1)) 0
  printf '+'
  for ((i=1;i<FRAME_W-1;i++)); do printf '-'; done
  printf '+'
}

draw_message(){
  local frow=$(((FRAME_H-2)/2))
  local fstart=$(( (FRAME_W-2 - ${#MSG}) / 2 ))
  cup $((frow+1)) $((fstart+1))
  printf '%s' "$MSG"
}

# run
tput civis
clear
draw_frame
draw_message
sleep 1
cleanup
