function brdn
    # Get current brightness from the main display (the one marked as "main")
    set current (brightness -l | grep -A1 "main" | grep "brightness" | awk '{print $4}')

    if test -z "$current"
        echo "Could not get current brightness from main display"
        return 1
    end

    # Calculate the new brightness for main display
    set main_bright (math "$current - 0.06")

    # Min 0 for main display
    if test $main_bright -lt 0
        set main_bright 0
    end

    # Calculate brightness for side displays (slightly lower)
    set side_bright (math "$main_bright - 0.08")

    # Min 0 for side displays
    if test $side_bright -lt 0
        set side_bright 0
    end

    # Get display IDs (not numbers) for more reliable identification
    set main_display_id (brightness -l | grep "main" | grep -o "ID 0x[0-9a-fA-F]*" | awk '{print $2}')
    set all_display_ids (brightness -l | grep "ID 0x" | grep -o "ID 0x[0-9a-fA-F]*" | awk '{print $2}')

    if test -z "$main_display_id"
        echo "Could not find main display ID"
        return 1
    end

    if test (count $all_display_ids) -eq 0
        echo "No display IDs found"
        return 1
    end

    # Apply brightness to all displays using their actual IDs
    for id in $all_display_ids
        if test "$id" = "$main_display_id"
            # Main display (center) - higher brightness
            brightness -d $id $main_bright
        else
            # Side displays - lower brightness
            brightness -d $id $side_bright
        end
    end

    echo "Main display brightness: $main_bright, Side displays brightness: $side_bright"
end
