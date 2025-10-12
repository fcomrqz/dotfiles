function brup
    # Get current brightness from the main display (display 0)
    set current (brightness -l | grep "brightness" | head -n 1 | awk '{print $4}')

    if test -z "$current"
        echo "Could not get current brightness"
        return 1
    end

    # Calculate the new brightness for main display
    set main_bright (math "$current + 0.06")

    # Max 1 for main display
    if test $main_bright -gt 1
        set main_bright 1
    end

    # Calculate brightness for side displays (slightly lower)
    set side_bright (math "$main_bright - 0.08")

    # Min 0 for side displays
    if test $side_bright -lt 0
        set side_bright 0
    end

    # Get all display numbers
    set display_nums (brightness -l | grep "^display" | awk '{print $2}' | tr -d ':')

    if test (count $display_nums) -eq 0
        echo "No displays found"
        return 1
    end

    # Apply brightness to all displays
    for num in $display_nums
        if test $num -eq 0
            # Main display (center) - higher brightness
            brightness -d $num $main_bright
        else
            # Side displays - lower brightness
            brightness -d $num $side_bright
        end
    end

    echo "Main display brightness: $main_bright, Side displays brightness: $side_bright"
end
