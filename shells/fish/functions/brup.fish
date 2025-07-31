function brup
    # Extract the current brightness as a single value
    set current (brightness -l | grep brightness | head -n 1 | awk '{print $4}')

    # Calculate the new brightness
    set bright (math "$current + 0.03")

    # Max 1
    if test $bright -gt 1
        set bright 1
    end

    brightness -d 0 $bright
    brightness -d 1 (math "$bright - 0.06")
    brightness -d 2 (math "$bright - 0.06")
end
