function fish_title
    if set -q INSIDE_EMACS; and string match -q '*,term:*' -- $INSIDE_EMACS
        return
    end

    # Reuse the prompt's cached context without commit or status details.
    set -l title_context (fish_prompt --title-context | string collect)

    set -l command_name (status current-command)
    if set -q argv[1]; and test -n "$argv"
        set command_name $argv
    end
    set command_name (string replace -ra '[[:cntrl:]]+' ' ' -- "$command_name")
    set command_name (string trim -- "$command_name")

    printf "%s  ·  %s\n" "$title_context" "$command_name"
end
