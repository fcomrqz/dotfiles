#!/bin/zsh

WINDOW_ID=${YABAI_WINDOW_ID}

IS_FLOATING=$(yabai -m query --windows --window $WINDOW_ID | jq '.["is-floating"]')
CAN_RESIZE=$(yabai -m query --windows --window $WINDOW_ID | jq '.["can-resize"]')

# get width and height of the screen
SCREEN_WIDTH=$(yabai -m query --displays --display | jq '.frame.w')
SCREEN_HEIGHT=$(yabai -m query --displays --display | jq '.frame.h')

# get width and height of the window
WINDOW_WIDTH=$(yabai -m query --windows --window $WINDOW_ID | jq '.frame.w')
WINDOW_HEIGHT=$(yabai -m query --windows --window $WINDOW_ID | jq '.frame.h')

# calculate the position to center the window
WINDOW_X=$(echo "($SCREEN_WIDTH - $WINDOW_WIDTH) / 2" | bc)
WINDOW_Y=$(echo "($SCREEN_HEIGHT - $WINDOW_HEIGHT) / 2" | bc)

# move the window to the calculated position
if $CAN_RESIZE; then
  echo ''
else
  if $IS_FLOATING; then
    yabai -m window $WINDOW_ID --move abs:$WINDOW_X:400
  else
    yabai -m window $WINDOW_ID --toggle float --move abs:$WINDOW_X:400
  fi
fi
