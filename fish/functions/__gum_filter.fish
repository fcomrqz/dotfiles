# A Fish implementation of the single-select Gum 0.14.5 filter behavior used
# by these dotfiles.
#
# The scoring routine is derived from github.com/sahilm/fuzzy v0.1.1 and the
# interaction/rendering model follows charmbracelet/gum v0.14.5. Both are MIT
# licensed; see THIRD_PARTY_NOTICES.md.

function __gum_filter_strip_ansi --argument-names value
    string replace -ra '\e\[[0-9;?]*[ -/]*[@-~]' '' -- "$value"
end

function __gum_filter_rank --argument-names query
    set -l candidates $argv[2..-1]
    set -g __gum_filter_ranked_values
    set -g __gum_filter_ranked_indexes

    if test -z "$query"
        set -g __gum_filter_ranked_values $candidates
        for candidate_value in $candidates
            set -a __gum_filter_ranked_indexes ''
        end
        return 0
    end

    set -l scorer (
        path resolve \
            (path dirname (functions --details __gum_filter_rank))/__gum_filter_rank.awk
    )
    set -lx GUM_FILTER_QUERY "$query"
    # Apple awk only handles UTF-8 predictably in byte-oriented locales.
    set -lx LC_ALL C
    for record in (
        printf '%s\n' $candidates |
            command awk -f "$scorer" |
            command sort -t \t -k1,1nr -k2,2n |
            command head -n 256
    )
        set -l fields (string split \t -- "$record")
        set -a __gum_filter_ranked_values "$candidates[$fields[2]]"
        set -a __gum_filter_ranked_indexes "$fields[3]"
    end
end

function __gum_filter_read_key
    set -g __gum_filter_key
    read --null --nchars 1 --global __gum_filter_key
end

function __gum_filter_render_candidate --argument-names candidate indexes selected max_width final_row
    set -l tokens (string match -ar '\e\[[0-9;?]*[ -/]*[@-~]|.' -- "$candidate")
    set -l matched (string split , -- "$indexes")
    set -l available (math "max(1, $max_width - 2)")

    if test $selected -eq 1
        set_color blue >&2
        printf '▌' >&2
        set_color normal >&2
    else
        printf ' ' >&2
    end
    printf ' ' >&2

    set -l rendered 0
    set -l visible_index 0
    set -l active_sgr ''
    for token in $tokens
        test $rendered -lt $available; or break
        if string match -qr '^\e\[' -- "$token"
            printf '%s' "$token" >&2
            if string match -qr 'm$' -- "$token"
                if string match -qr '^\e\[(0(;0)*)?m$' -- "$token"
                    set active_sgr ''
                else
                    set active_sgr "$active_sgr$token"
                end
            end
            continue
        end

        set visible_index (math "$visible_index + 1")
        if contains -- $visible_index $matched
            set_color blue >&2
            printf '%s' "$token" >&2
            set_color normal >&2
            printf '%s' "$active_sgr" >&2
        else
            printf '%s' "$token" >&2
        end
        set rendered (math "$rendered + 1")
    end
    set_color normal >&2
    if test "$final_row" -eq 1
        printf '\033[K' >&2
    else
        printf '\033[K\n' >&2
    end
end

function __gum_filter_render --argument-names height cursor offset query query_cursor
    set -l terminal_width $COLUMNS
    if not set -q terminal_width[1]; or test "$terminal_width" -lt 10
        set terminal_width 80
    end

    # Hide the hardware cursor while repainting the rows below the query. If
    # left visible, terminals show it travel to the bottom and jump back up.
    # Each rendered row clears its own remainder, so clearing the whole region
    # here only makes the bottom rows disappear briefly before they are drawn.
    printf '\033[?25l\r' >&2
    set_color green >&2
    printf '→ ' >&2
    set_color normal >&2
    printf '%s\033[K\n' "$query" >&2

    for row in (seq $height)
        set -l match_index (math "$offset + $row - 1")
        set -l final_row 0
        test $row -eq $height; and set final_row 1
        if test $match_index -le (count $__gum_filter_ranked_values)
            set -l is_selected 0
            if test $match_index -eq $cursor
                set is_selected 1
            end
            __gum_filter_render_candidate \
                "$__gum_filter_ranked_values[$match_index]" \
                "$__gum_filter_ranked_indexes[$match_index]" \
                $is_selected \
                $terminal_width \
                $final_row
        else
            if test $final_row -eq 1
                printf '\033[K' >&2
            else
                printf '\033[K\n' >&2
            end
        end
    end

    # Leave the real terminal cursor in the query, like Gum's textinput.
    printf '\033[%dA\r' $height >&2
    set -l cursor_column (math "2 + $query_cursor")
    if test $cursor_column -gt 0
        printf '\033[%dC' $cursor_column >&2
    end
    printf '\033[?25h' >&2
end

function __gum_filter_restore_terminal
    if set -q __gum_filter_saved_stty[1]
        command stty "$__gum_filter_saved_stty" </dev/tty 2>/dev/null
    end
    printf '\033[?25h\r\033[J' >&2
    set_color normal >&2
    set -e __gum_filter_saved_stty
end

function __gum_filter --description 'Single-select filter matching the pinned Gum UI'
    argparse 'height=' 'query=' -- $argv
    or return 2

    set -l height 12
    set -q _flag_height; and set height $_flag_height
    set -l query ''
    set -q _flag_query; and set query $_flag_query
    set -l candidates $argv

    if test (count $candidates) -eq 0; and not test -t 0
        while read -l candidate
            set -a candidates "$candidate"
        end
    end
    if test (count $candidates) -eq 0
        return 1
    end
    if not test -t 2
        return 1
    end
    if test "$height" -lt 1
        set height 1
    end

    set -g __gum_filter_saved_stty (command stty -g </dev/tty)
    or return 1
    command stty -echo -icanon -isig min 1 time 0 </dev/tty
    or begin
        set -e __gum_filter_saved_stty
        return 1
    end

    set -l query_cursor (string length -- "$query")
    set -l cursor 1
    set -l offset 1
    set -l selected ''
    set -l result_status 0

    __gum_filter_rank "$query" $candidates
    set -l ranked_query "$query"

    while true
        if test "$query" != "$ranked_query"
            __gum_filter_rank "$query" $candidates
            set cursor 1
            set offset 1
            set ranked_query "$query"
        end

        set -l match_count (count $__gum_filter_ranked_values)
        if test $match_count -eq 0
            set cursor 0
            set offset 1
        else
            if test $cursor -lt 1
                set cursor 1
            else if test $cursor -gt $match_count
                set cursor $match_count
            end
            if test $cursor -lt $offset
                set offset $cursor
            else if test $cursor -ge (math "$offset + $height")
                set offset (math "$cursor - $height + 1")
            end
        end

        __gum_filter_render $height $cursor $offset "$query" $query_cursor
        __gum_filter_read_key </dev/tty
        or continue
        set -l key "$__gum_filter_key"

        switch "$key"
            case \cc
                set result_status 130
                break
            case \n \r
                if test $cursor -gt 0
                    set selected (__gum_filter_strip_ansi "$__gum_filter_ranked_values[$cursor]")
                end
                break
            case \cn
                if test $match_count -gt 0
                    set cursor (math "$cursor % $match_count + 1")
                end
            case \ck \cp
                if test $match_count -gt 0
                    set cursor (math "($cursor - 2 + $match_count) % $match_count + 1")
                end
            case \ca
                set query_cursor 0
            case \ce
                set query_cursor (string length -- "$query")
            case \cu
                set query (string sub -s (math "$query_cursor + 1") -- "$query")
                set query_cursor 0
            case \cw
                if test $query_cursor -gt 0
                    set -l before (string sub -s 1 -l $query_cursor -- "$query")
                    set -l after ''
                    if test $query_cursor -lt (string length -- "$query")
                        set after (string sub -s (math "$query_cursor + 1") -- "$query")
                    end
                    set before (string replace -r '[[:space:]]*[^[:space:]]+[[:space:]]*$' '' -- "$before")
                    set query "$before$after"
                    set query_cursor (string length -- "$before")
                end
            case \x7f \b
                if test $query_cursor -gt 0
                    set -l before ''
                    set -l after ''
                    if test $query_cursor -gt 1
                        set before (string sub -s 1 -l (math "$query_cursor - 1") -- "$query")
                    end
                    if test $query_cursor -lt (string length -- "$query")
                        set after (string sub -s (math "$query_cursor + 1") -- "$query")
                    end
                    set query "$before$after"
                    set query_cursor (math "$query_cursor - 1")
                end
            case \e
                command stty min 0 time 1 </dev/tty
                __gum_filter_read_key </dev/tty
                set -l escape_status $status
                set -l second "$__gum_filter_key"
                command stty min 1 time 0 </dev/tty
                if test $escape_status -ne 0
                    set result_status 130
                    break
                end
                if contains -- "$second" \[ O
                    __gum_filter_read_key </dev/tty
                    or continue
                    set -l third "$__gum_filter_key"
                    switch "$third"
                        case A
                            if test $match_count -gt 0
                                set cursor (math "($cursor - 2 + $match_count) % $match_count + 1")
                            end
                        case B
                            if test $match_count -gt 0
                                set cursor (math "$cursor % $match_count + 1")
                            end
                        case C
                            if test $query_cursor -lt (string length -- "$query")
                                set query_cursor (math "$query_cursor + 1")
                            end
                        case D
                            if test $query_cursor -gt 0
                                set query_cursor (math "$query_cursor - 1")
                            end
                        case H
                            set query_cursor 0
                        case F
                            set query_cursor (string length -- "$query")
                        case 3
                            __gum_filter_read_key </dev/tty
                            or continue
                            if test "$__gum_filter_key" = \~
                                set -l query_length (string length -- "$query")
                                if test $query_cursor -lt $query_length
                                    set -l before ''
                                    set -l after ''
                                    if test $query_cursor -gt 0
                                        set before (string sub -s 1 -l $query_cursor -- "$query")
                                    end
                                    if test (math "$query_cursor + 2") -le $query_length
                                        set after (string sub -s (math "$query_cursor + 2") -- "$query")
                                    end
                                    set query "$before$after"
                                end
                            end
                    end
                end
            case '*'
                if not string match -qr '[[:cntrl:]]' -- "$key"
                    set -l before ''
                    set -l after ''
                    if test $query_cursor -gt 0
                        set before (string sub -s 1 -l $query_cursor -- "$query")
                    end
                    if test $query_cursor -lt (string length -- "$query")
                        set after (string sub -s (math "$query_cursor + 1") -- "$query")
                    end
                    set query "$before$key$after"
                    set query_cursor (math "$query_cursor + 1")
                end
        end
    end

    __gum_filter_restore_terminal
    set -e __gum_filter_key __gum_filter_ranked_values __gum_filter_ranked_indexes

    if test $result_status -ne 0
        return $result_status
    end
    if test -n "$selected"
        printf '%s\n' "$selected"
    end
end
