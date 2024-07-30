#!/bin/fish

set window_id (yabai -m query --windows --window | jq '.id')

set is_native_fullscreen (yabai -m query --windows --window | jq '."is-native-fullscreen"')

if test $is_native_fullscreen = true
    yabai -m window --toggle native-fullscreen
end

set display (yabai -m query --windows --window $window_id | jq '.display')

if test $display -eq "1"
    yabai -m window --swap east
    if test $status -eq 1
        yabai -m window --display east
        yabai -m window $window_id --focus
    end
else if test $display -eq "2"
    yabai -m window --display east
    if test $status -eq 1
        yabai -m window --display 3
    end
    yabai -m window $window_id --focus
else if test $display -eq "3"
    yabai -m window --swap next
    if test $status -eq 1
        yabai -m window --swap prev
    end
end
