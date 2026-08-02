function orb --wraps /opt/homebrew/bin/orb
    if test (count $argv) -eq 0
        ssh orb
    else
        command orb $argv
    end
end
