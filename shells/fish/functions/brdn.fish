function brdn
    # Extract the current brightness as a single value
    set current (brightness -l | grep brightness | head -n 1 | awk '{print $4}')

    # Calculate the new brightness
    set bright (math "$current - 0.03")

    # Min 0
    if test $bright -lt 0
        set bright 0
    end

    brightness -d 0 $bright
    brightness -d 1 (math "$bright - 0.06")
    brightness -d 2 (math "$bright - 0.06")
end
