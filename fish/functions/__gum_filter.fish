# A Fish implementation of the single-select Gum 0.14.5 filter behavior used
# by these dotfiles.
#
# The scoring routine is derived from github.com/sahilm/fuzzy v0.1.1 and the
# interaction/rendering model follows charmbracelet/gum v0.14.5. Both are MIT
# licensed; see THIRD_PARTY_NOTICES.md.

function __gum_filter_strip_ansi --argument-names value
    string replace -ra '\e\[[0-9;?]*[ -/]*[@-~]' '' -- "$value"
end

function __gum_filter_score --argument-names pattern candidate
    set -g __gum_filter_score_value
    set -g __gum_filter_score_indexes

    set -l pattern_chars (string split '' -- "$pattern")
    set -l pattern_lower (string split '' -- (string lower -- "$pattern"))
    set -l candidate_chars (string split '' -- "$candidate")
    set -l candidate_lower (string split '' -- (string lower -- "$candidate"))

    if test (count $pattern_chars) -eq 0
        set -g __gum_filter_score_value 0
        return 0
    end

    set -l pattern_index 1
    set -l best_score -1
    set -l best_index 0
    set -l total_score 0
    set -l adjacent_bonus 0
    set -l matched_indexes
    set -l last_char ''
    set -l last_index 0

    for candidate_index in (seq (count $candidate_chars))
        if test "$candidate_lower[$candidate_index]" = "$pattern_lower[$pattern_index]"
            set -l score 0
            if test $candidate_index -eq 1
                set score (math "$score + 10")
            end
            if string match -qr '^[[:lower:]]$' -- "$last_char"
                if string match -qr '^[[:upper:]]$' -- "$candidate_chars[$candidate_index]"
                    set score (math "$score + 20")
                end
            end
            if test $candidate_index -ne 1
                if contains -- "$last_char" / - _ ' ' . \\
                    set score (math "$score + 20")
                end
            end
            if test (count $matched_indexes) -gt 0
                if test "$matched_indexes[-1]" -eq "$last_index"
                    set -l bonus (math "$adjacent_bonus * 2 + 5")
                    set score (math "$score + $bonus")
                    set adjacent_bonus (math "$adjacent_bonus + $bonus")
                end
            end
            if test $score -gt $best_score
                set best_score $score
                set best_index $candidate_index
            end
        end

        set -l next_pattern ''
        set -l next_candidate ''
        if test $pattern_index -lt (count $pattern_lower)
            set -l next_pattern_index (math "$pattern_index + 1")
            set next_pattern "$pattern_lower[$next_pattern_index]"
        end
        if test $candidate_index -lt (count $candidate_lower)
            set -l next_candidate_index (math "$candidate_index + 1")
            set next_candidate "$candidate_lower[$next_candidate_index]"
        end

        if test -z "$next_candidate"; or test "$next_pattern" = "$next_candidate"
            if test $best_index -gt 0
                if test (count $matched_indexes) -eq 0
                    set -l leading_penalty (math "($best_index - 1) * -5")
                    if test $leading_penalty -lt -15
                        set leading_penalty -15
                    end
                    set best_score (math "$best_score + $leading_penalty")
                end
                set total_score (math "$total_score + $best_score")
                set -a matched_indexes $best_index
                set best_score -1
                set best_index 0
                set pattern_index (math "$pattern_index + 1")
                if test $pattern_index -gt (count $pattern_lower)
                    break
                end
            end
        end

        set last_index $candidate_index
        set last_char "$candidate_chars[$candidate_index]"
    end

    set total_score (math "$total_score + "(count $matched_indexes)" - "(count $candidate_chars))
    if test (count $matched_indexes) -eq (count $pattern_chars)
        set -g __gum_filter_score_value $total_score
        set -g __gum_filter_score_indexes $matched_indexes
        return 0
    end
    return 1
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

    set -l sortable
    for candidate_index in (seq (count $candidates))
        set -l plain (__gum_filter_strip_ansi "$candidates[$candidate_index]")
        if __gum_filter_score "$query" "$plain"
            set -a sortable "$__gum_filter_score_value\t$candidate_index\t"(string join , $__gum_filter_score_indexes)
        end
    end

    for record in (printf '%b\n' $sortable | command sort -t \t -k1,1nr -k2,2n)
        set -l fields (string split \t -- "$record")
        set -a __gum_filter_ranked_values "$candidates[$fields[2]]"
        set -a __gum_filter_ranked_indexes "$fields[3]"
    end
end

function __gum_filter_read_byte
    command dd if=/dev/tty bs=1 count=1 2>/dev/null |
        command od -An -tu1 |
        string trim
end

function __gum_filter_read_character --argument-names first_byte
    set -l byte_count 1
    if test $first_byte -ge 194 -a $first_byte -le 223
        set byte_count 2
    else if test $first_byte -ge 224 -a $first_byte -le 239
        set byte_count 3
    else if test $first_byte -ge 240 -a $first_byte -le 244
        set byte_count 4
    end

    set -l escaped (printf '\\x%02x' $first_byte)
    for continuation_index in (seq 2 $byte_count)
        set -l next_byte (__gum_filter_read_byte)
        test -n "$next_byte"; or break
        set escaped "$escaped"(printf '\\x%02x' $next_byte)
    end
    printf '%b' "$escaped"
end

function __gum_filter_render_candidate --argument-names candidate indexes selected max_width
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
    printf '\033[K\n' >&2
end

function __gum_filter_render --argument-names height cursor offset query query_cursor
    set -l terminal_width $COLUMNS
    if not set -q terminal_width[1]; or test "$terminal_width" -lt 10
        set terminal_width 80
    end

    printf '\r\033[J' >&2
    set_color green >&2
    printf '→ ' >&2
    set_color normal >&2
    printf '%s\033[K\n' "$query" >&2

    for row in (seq $height)
        set -l match_index (math "$offset + $row - 1")
        if test $match_index -le (count $__gum_filter_ranked_values)
            set -l is_selected 0
            if test $match_index -eq $cursor
                set is_selected 1
            end
            __gum_filter_render_candidate \
                "$__gum_filter_ranked_values[$match_index]" \
                "$__gum_filter_ranked_indexes[$match_index]" \
                $is_selected \
                $terminal_width
        else
            printf '\033[K\n' >&2
        end
    end

    # Leave the real terminal cursor in the query, like Gum's textinput.
    printf '\033[%dA\r' (math "$height + 1") >&2
    set -l cursor_column (math "2 + $query_cursor")
    if test $cursor_column -gt 0
        printf '\033[%dC' $cursor_column >&2
    end
end

function __gum_filter_restore_terminal
    if set -q __gum_filter_saved_stty[1]
        command stty "$__gum_filter_saved_stty" </dev/tty 2>/dev/null
    end
    printf '\r\033[J' >&2
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

    while true
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
        set -l byte (__gum_filter_read_byte)
        test -n "$byte"; or continue

        switch $byte
            case 3
                set result_status 130
                break
            case 13
                if test $cursor -gt 0
                    set selected (__gum_filter_strip_ansi "$__gum_filter_ranked_values[$cursor]")
                end
                break
            case 10 14
                if test $match_count -gt 0
                    set cursor (math "$cursor % $match_count + 1")
                end
            case 11 16
                if test $match_count -gt 0
                    set cursor (math "($cursor - 2 + $match_count) % $match_count + 1")
                end
            case 1
                set query_cursor 0
            case 5
                set query_cursor (string length -- "$query")
            case 21
                set query (string sub -s (math "$query_cursor + 1") -- "$query")
                set query_cursor 0
                __gum_filter_rank "$query" $candidates
            case 23
                if test $query_cursor -gt 0
                    set -l before (string sub -s 1 -l $query_cursor -- "$query")
                    set -l after ''
                    if test $query_cursor -lt (string length -- "$query")
                        set after (string sub -s (math "$query_cursor + 1") -- "$query")
                    end
                    set before (string replace -r '[[:space:]]*[^[:space:]]+[[:space:]]*$' '' -- "$before")
                    set query "$before$after"
                    set query_cursor (string length -- "$before")
                    __gum_filter_rank "$query" $candidates
                end
            case 127 8
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
                    __gum_filter_rank "$query" $candidates
                end
            case 27
                command stty min 0 time 1 </dev/tty
                set -l second (__gum_filter_read_byte)
                command stty min 1 time 0 </dev/tty
                if test -z "$second"
                    set result_status 130
                    break
                end
                if test "$second" = 91
                    set -l third (__gum_filter_read_byte)
                    switch $third
                        case 65
                            if test $match_count -gt 0
                                set cursor (math "($cursor - 2 + $match_count) % $match_count + 1")
                            end
                        case 66
                            if test $match_count -gt 0
                                set cursor (math "$cursor % $match_count + 1")
                            end
                        case 67
                            if test $query_cursor -lt (string length -- "$query")
                                set query_cursor (math "$query_cursor + 1")
                            end
                        case 68
                            if test $query_cursor -gt 0
                                set query_cursor (math "$query_cursor - 1")
                            end
                        case 72
                            set query_cursor 0
                        case 70
                            set query_cursor (string length -- "$query")
                        case 51
                            set -l fourth (__gum_filter_read_byte)
                            if test "$fourth" = 126
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
                                    __gum_filter_rank "$query" $candidates
                                end
                            end
                    end
                end
            case '*'
                if test $byte -ge 32
                    set -l character (__gum_filter_read_character $byte)
                    set -l before ''
                    set -l after ''
                    if test $query_cursor -gt 0
                        set before (string sub -s 1 -l $query_cursor -- "$query")
                    end
                    if test $query_cursor -lt (string length -- "$query")
                        set after (string sub -s (math "$query_cursor + 1") -- "$query")
                    end
                    set query "$before$character$after"
                    set query_cursor (math "$query_cursor + 1")
                    __gum_filter_rank "$query" $candidates
                end
        end
    end

    __gum_filter_restore_terminal
    set -e __gum_filter_ranked_values __gum_filter_ranked_indexes

    if test $result_status -ne 0
        return $result_status
    end
    if test -n "$selected"
        printf '%s\n' "$selected"
    end
end
