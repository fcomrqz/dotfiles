#!/bin/zsh

WINDOW_ID=${YABAI_WINDOW_ID}

SPLIT_CHILD=$(yabai -m query --windows --window $WINDOW_ID | jq '.["split-child"]')
LAYER=$(yabai -m query --windows --window $WINDOW_ID | jq '.["layer"]')

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

if [ "$SPLIT_CHILD" == "\"none\"" ] && [ "$LAYER" == "\"unknown\"" ]; then
  yabai -m window $WINDOW_ID --move abs:$WINDOW_X:460
fi
