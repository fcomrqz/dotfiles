set -e __fish_prompt_os
set -e __fish_prompt_context_cache_pwd
set -e __fish_prompt_context_cache_value
set -e __fish_prompt_context_cache_repository
set -e __fish_prompt_context_cache_branch
set -e __fish_prompt_context_cache_head
set -e __fish_prompt_context_cache_is_github
set -e __fish_prompt_title_context_cache_value
set -e __fish_prompt_tag_cache_pwd
set -e __fish_prompt_tag_cache_head
set -e __fish_prompt_tag_cache_value
set -e __fish_prompt_git_render_cache
set -e __fish_prompt_pr_current_key
set -e __fish_prompt_pr_cache_key
set -e __fish_prompt_pr_number
set -e __fish_prompt_pr_state
set -e __fish_prompt_pr_is_draft
set -e __fish_prompt_pr_check_state
set -e __fish_prompt_pr_request_key
set -e __fish_prompt_pr_worker_pid
set -e __fish_prompt_spinner_active
set -e __fish_prompt_spinner_frames
set -e __fish_prompt_spinner_frame
set -e __fish_prompt_spinner_ticks
set -e __fish_prompt_spinner_tick_pid
set -e __fish_prompt_command_running

function fish_prompt
    set -l last_status $status

    if contains -- --title-context $argv
        __fish_prompt_command_context --title-context
        return
    end

    set -l header_color yellow
    set -l final_rendering 0
    if contains -- --final-rendering $argv
        set header_color brblack
        set final_rendering 1
    end

    __fish_prompt_command_context >/dev/null
    if test -n "$__fish_prompt_os"
        if test $final_rendering -eq 1
            set_color brblack
        else
            set_color yellow
        end
        printf "%s " "$__fish_prompt_os"
    end

    if test $final_rendering -eq 1
        set_color brblack
    else
        set_color yellow
    end
    printf "%s" "$__fish_prompt_context_cache_repository"
    if test -n "$__fish_prompt_context_cache_branch"
        if test $final_rendering -eq 1
            set_color brblack
        else
            set_color magenta
        end
        printf " %s" "$__fish_prompt_context_cache_branch"
    end

    if test $final_rendering -eq 0
        __fish_prompt_pr_prepare
    end

    printf " "
    set_color normal
    if test -n "$DIRENV_DIR"
        set_color $header_color
        printf "* "
        set_color normal
    end

    if test $final_rendering -eq 0
        __fish_prompt_spinner_sync
        __fish_prompt_render_git_status
    else
        __fish_prompt_spinner_stop
    end

    __fish_prompt_pr_render $final_rendering
    printf " "
    set_color normal

    printf "\n"
    if test $last_status -eq 0
        set_color green
        printf "%s" "→"
    else
        set_color red
        printf "%s" "×"
    end
    set_color normal
    printf " "
end

function __fish_prompt_render_git_status
    if test "$__fish_prompt_spinner_active" = 1
        and set -q __fish_prompt_git_render_cache
        printf "%s" "$__fish_prompt_git_render_cache"
        return
    end

    set -g __fish_prompt_git_render_cache (__fish_prompt_git_status | string collect)
    printf "%s" "$__fish_prompt_git_render_cache"
end

function __fish_prompt_git_status
    set -l is_synced 1
    set -l has_upstream 0
    set -l ahead 0
    set -l behind 0
    set -l has_conflicts 0
    set -l has_dirty 0
    set -l has_staged 0
    set -l git_head ""
    set -l operation ""
    set -l operation_color ""

    set -l status_lines (git status --porcelain=v2 --branch 2>/dev/null)
    or return

    for line in $status_lines
        switch $line
            case '# branch.oid *'
                set git_head (string replace '# branch.oid ' '' -- $line)
            case '# branch.ab *'
                set has_upstream 1
                set -l counts (string match -r '# branch.ab \+([0-9]+) -([0-9]+)' -- $line)
                if test (count $counts) -ge 3
                    set ahead $counts[2]
                    set behind $counts[3]
                end
            case 'u *'
                set has_conflicts 1
                set is_synced 0
            case '? *'
                set has_dirty 1
                set is_synced 0
            case '1 *' '2 *'
                set -l xy (string sub -s 3 -l 2 -- $line)
                set -l index_status (string sub -s 1 -l 1 -- $xy)
                set -l worktree_status (string sub -s 2 -l 1 -- $xy)

                if test "$worktree_status" != "."
                    set has_dirty 1
                    set is_synced 0
                end

                if test "$index_status" != "."
                    set has_staged 1
                    set is_synced 0
                end
        end
    end

    if test "$ahead" -gt 0; or test "$behind" -gt 0
        set is_synced 0
    end

    if not set -q __git_dir_cache_pwd; or test "$PWD" != "$__git_dir_cache_pwd"; or not set -q __git_dir_cache_value
        set -g __git_dir_cache_pwd $PWD
        set -g __git_dir_cache_value (git rev-parse --git-dir 2>/dev/null)
    end

    set -l git_dir $__git_dir_cache_value
    if test -n "$git_dir"
        if test -d "$git_dir/rebase-merge"; or test -d "$git_dir/rebase-apply"
            set operation rebasing
            set operation_color cyan
            set is_synced 0
        else if test -f "$git_dir/MERGE_HEAD"
            set operation merging
            set operation_color yellow
            set is_synced 0
        else if test -f "$git_dir/CHERRY_PICK_HEAD"
            set operation "cherry picking"
            set operation_color red
            set is_synced 0
        else if test -f "$git_dir/BISECT_LOG"
            set operation bisecting
            set operation_color red
            set is_synced 0
        end
    end

    set -l tag
    if not set -q __fish_prompt_tag_cache_pwd __fish_prompt_tag_cache_head __fish_prompt_tag_cache_value
        or test "$PWD" != "$__fish_prompt_tag_cache_pwd"
        or test "$git_head" != "$__fish_prompt_tag_cache_head"
        set -g __fish_prompt_tag_cache_pwd $PWD
        set -g __fish_prompt_tag_cache_head $git_head
        set -g __fish_prompt_tag_cache_value

        if test -n "$git_head"; and test "$git_head" != "(initial)"
            set -l exact_tags (git tag --points-at "$git_head" --sort=-version:refname 2>/dev/null)
            for candidate in $exact_tags
                string match --quiet 'release*' -- "$candidate"; and continue
                set -g __fish_prompt_tag_cache_value $candidate
                break
            end
        end
    end
    set tag $__fish_prompt_tag_cache_value

    if test "$behind" -gt 0
        set_color red
        printf "↓ "
        set_color normal
    end

    if test "$ahead" -gt 0
        set_color green
        printf "↑ "
        set_color normal
    end

    if test -n "$operation"
        set_color $operation_color
        printf "%s " "$operation"
        set_color normal
    end

    if test $has_conflicts -eq 1
        set_color red
        printf "! "
        set_color normal
    end

    if test $has_dirty -eq 1
        set_color yellow
        printf "* "
        set_color normal
    end

    if test $has_staged -eq 1
        set_color blue
        printf "* "
        set_color normal
    end

    if test $is_synced -eq 1; and test $has_upstream -eq 1
        set_color green
        printf "✓ "
        set_color normal
    end

    if test -n "$tag"
        set_color brmagenta
        printf "%s " "$tag"
        set_color normal
    end
end

function __fish_prompt_display_path
    set -l location (path normalize "$argv[1]")
    set -l home (path normalize "$HOME")

    if test "$location" = "$home"
        printf '~'
    else if string match --quiet "$home/*" "$location"
        printf '~%s' (string sub -s (math (string length "$home") + 1) -- "$location")
    else
        printf '%s' "$location"
    end
end

function __fish_prompt_command_context
    set -l title_context 0
    contains -- --title-context $argv; and set title_context 1

    if set -q __fish_prompt_context_cache_pwd __fish_prompt_context_cache_value \
            __fish_prompt_context_cache_repository __fish_prompt_context_cache_branch \
            __fish_prompt_context_cache_head __fish_prompt_context_cache_is_github \
            __fish_prompt_title_context_cache_value
        and test "$PWD" = "$__fish_prompt_context_cache_pwd"
        if test $title_context -eq 1
            printf "%s" "$__fish_prompt_title_context_cache_value"
        else
            printf "%s" "$__fish_prompt_context_cache_value"
        end
        return
    end

    if not set -q __fish_prompt_os
        set -g __fish_prompt_os
        switch (uname)
            case Linux
                set -g __fish_prompt_os "⌁"
        end
    end

    set -l repository (__fish_prompt_display_path "$PWD")
    set -l branch
    set -l commit
    set -g __fish_prompt_context_cache_is_github 0
    set -l git_info (command git rev-parse --git-common-dir --git-dir --short HEAD 2>/dev/null)

    if test (count $git_info) -ge 2
        set -l common_dir $git_info[1]
        set -l git_dir $git_info[2]
        if test (count $git_info) -ge 3
            set commit $git_info[3]
        end

        if not string match --quiet --regex '^/' "$common_dir"
            set common_dir (path resolve "$common_dir")
        end
        if not string match --quiet --regex '^/' "$git_dir"
            set git_dir (path resolve "$git_dir")
        end

        if test (path basename "$common_dir") = .git
            set repository (path basename (path dirname "$common_dir"))
        else
            set repository (path basename "$common_dir")
        end

        # Prefer GitHub's canonical repository name when origin points there,
        # supporting HTTPS, SSH URLs, and SCP-style SSH remotes.
        set -l origin_url (command git config --get remote.origin.url 2>/dev/null)
        if string match --quiet --ignore-case --regex 'github\.com[/:]' "$origin_url"
            set -g __fish_prompt_context_cache_is_github 1
            set -l github_path (string replace -r '^.*github\.com[/:]' '' -- "$origin_url")
            set github_path (string replace -r '[?#].*$' '' -- "$github_path")
            set github_path (string replace -r '\.git/?$' '' -- "$github_path")
            set github_path (string trim -c / -- "$github_path")
            set -l github_parts (string split / -- "$github_path")
            if test (count $github_parts) -ge 2
                set repository $github_parts[-1]
            end
        end

        # Reading HEAD avoids another Git process on every cache refresh.
        if test -r "$git_dir/HEAD"
            set -l head (string trim -- (string collect <"$git_dir/HEAD"))
            set -l head_ref (string match -r '^ref: refs/heads/(.+)$' -- "$head")
            if test (count $head_ref) -ge 2
                set branch $head_ref[2]
            else if string match --quiet --regex '^[0-9a-fA-F]{7,}$' "$head"
                if test -n "$commit"
                    set branch "@$commit"
                else
                    set branch "@"(string sub -s 1 -l 7 -- "$head")
                end
            end
        end
    end

    set -g __fish_prompt_context_cache_repository (string replace -ra '[[:cntrl:]]' '' -- "$repository")
    set -g __fish_prompt_context_cache_branch
    set -g __fish_prompt_context_cache_head $commit
    if test -n "$branch"
        set -g __fish_prompt_context_cache_branch (string replace -ra '[[:cntrl:]]' '' -- "$branch")
    end

    set -l fields $__fish_prompt_os $__fish_prompt_context_cache_repository \
        $__fish_prompt_context_cache_branch
    set -l safe_fields
    for field in $fields
        test -n "$field"; or continue
        set -a safe_fields (string replace -ra '[[:cntrl:]]' '' -- "$field")
    end

    set -g __fish_prompt_context_cache_pwd $PWD
    set -g __fish_prompt_context_cache_value (string join " " -- $safe_fields)

    set -l title_fields $__fish_prompt_os $repository
    set -l safe_title_fields
    for field in $title_fields
        test -n "$field"; or continue
        set -a safe_title_fields (string replace -ra '[[:cntrl:]]' '' -- "$field")
    end
    if test (count $safe_title_fields) -ge 2
        set -l title_details (string join "  " -- $safe_title_fields[2..-1])
        set -g __fish_prompt_title_context_cache_value "$safe_title_fields[1]  $title_details"
    else
        set -g __fish_prompt_title_context_cache_value (string join " " -- $safe_title_fields)
    end
    if test -n "$branch"
        set -l safe_branch (string replace -ra '[[:cntrl:]]' '' -- "$branch")
        set -g __fish_prompt_title_context_cache_value "$__fish_prompt_title_context_cache_value  $safe_branch"
    end

    if test $title_context -eq 1
        printf "%s" "$__fish_prompt_title_context_cache_value"
    else
        printf "%s" "$__fish_prompt_context_cache_value"
    end
end

function __fish_prompt_pr_clear
    set -e __fish_prompt_pr_cache_key
    set -e __fish_prompt_pr_number
    set -e __fish_prompt_pr_state
    set -e __fish_prompt_pr_is_draft
    set -e __fish_prompt_pr_check_state
end

function __fish_prompt_pr_prepare
    if test "$__fish_prompt_context_cache_is_github" != 1
        or test -z "$__fish_prompt_context_cache_branch"
        or not command -sq gh
        set -e __fish_prompt_pr_current_key
        __fish_prompt_pr_clear
        return
    end

    set -g __fish_prompt_pr_current_key (string join \x1e -- \
        "$PWD" "$__fish_prompt_context_cache_branch" "$__fish_prompt_context_cache_head")

    if not set -q __fish_prompt_pr_cache_key
        or test "$__fish_prompt_pr_cache_key" != "$__fish_prompt_pr_current_key"
        __fish_prompt_pr_clear
    end

    if not set -q __fish_prompt_pr_cache_key
        and not set -q __fish_prompt_pr_worker_pid
        __fish_prompt_pr_request "$__fish_prompt_pr_current_key"
    end
end

function __fish_prompt_pr_request
    set -l request_key "$argv[1]"
    test -n "$request_key"; or return
    set -q __fish_prompt_pr_worker_pid; and return

    set -l output_file (mktemp -t fish-prompt-pr-output.XXXXXX)
    or return
    set -l error_file (mktemp -t fish-prompt-pr-error.XXXXXX)
    or begin
        command rm -f -- "$output_file"
        return
    end

    set -l query '
        .number as $number |
        .state as $state |
        .isDraft as $draft |
        [.statusCheckRollup[] |
            if .__typename == "CheckRun" then
                if .status != "COMPLETED" then "pending"
                elif (.conclusion == "FAILURE" or
                      .conclusion == "TIMED_OUT" or
                      .conclusion == "CANCELLED" or
                      .conclusion == "ACTION_REQUIRED" or
                      .conclusion == "STARTUP_FAILURE") then "fail"
                else "pass"
                end
            else
                if (.state == "PENDING" or .state == "EXPECTED") then "pending"
                elif (.state == "ERROR" or .state == "FAILURE") then "fail"
                else "pass"
                end
            end
        ] as $checks |
        [$number, $state, $draft,
            (if ($checks | index("fail")) then "fail"
             elif ($checks | index("pending")) then "pending"
             elif ($checks | length) > 0 then "pass"
             else "none"
             end)] | @tsv
    '

    command gh pr view --json number,state,isDraft,statusCheckRollup \
        --jq "$query" >"$output_file" 2>"$error_file" &
    set -l worker_pid $last_pid
    set -g __fish_prompt_pr_worker_pid $worker_pid
    set -g __fish_prompt_pr_request_key $request_key
    set -l handler_name __fish_prompt_pr_worker_done_$worker_pid

    function $handler_name --on-process-exit $worker_pid \
        --inherit-variable handler_name \
        --inherit-variable worker_pid \
        --inherit-variable request_key \
        --inherit-variable output_file \
        --inherit-variable error_file
        functions -e $handler_name

        set -l worker_status $argv[3]
        set -l result (string collect <"$output_file")
        set -l error_text (string collect <"$error_file")
        command rm -f -- "$output_file" "$error_file"

        if set -q __fish_prompt_pr_worker_pid
            and test "$__fish_prompt_pr_worker_pid" = "$worker_pid"
            set -e __fish_prompt_pr_worker_pid
            set -e __fish_prompt_pr_request_key
        end

        if test "$request_key" = "$__fish_prompt_pr_current_key"
            set -g __fish_prompt_pr_cache_key $request_key
            set -g __fish_prompt_pr_number
            set -g __fish_prompt_pr_state
            set -g __fish_prompt_pr_is_draft
            set -g __fish_prompt_pr_check_state

            if test "$worker_status" -eq 0
                set -l fields (string split \t -- (string trim -- "$result"))
                if test (count $fields) -ge 4
                    set -g __fish_prompt_pr_number $fields[1]
                    set -g __fish_prompt_pr_state (string lower -- "$fields[2]")
                    set -g __fish_prompt_pr_is_draft $fields[3]
                    set -g __fish_prompt_pr_check_state $fields[4]
                end
            else if not string match --quiet '*no pull requests found*' -- "$error_text"
                # Cache transient failures too; a branch or HEAD change retries.
                set -g __fish_prompt_pr_check_state error
            end
        end

        __fish_prompt_repaint
    end
end

function __fish_prompt_spinner_needs_animation
    if set -q __fish_prompt_pr_cache_key
        and test "$__fish_prompt_pr_cache_key" = "$__fish_prompt_pr_current_key"
        and test "$__fish_prompt_pr_state" = open
        and test "$__fish_prompt_pr_is_draft" != true
        and test "$__fish_prompt_pr_check_state" = pending
        return 0
    end

    return 1
end

function __fish_prompt_spinner_start
    set -g __fish_prompt_spinner_active 1
    if not set -q __fish_prompt_spinner_frames
        set -g __fish_prompt_spinner_frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    end
    set -q __fish_prompt_spinner_frame; or set -g __fish_prompt_spinner_frame 1
    set -q __fish_prompt_spinner_ticks; or set -g __fish_prompt_spinner_ticks 0
    set -q __fish_prompt_spinner_tick_pid; or __fish_prompt_spinner_schedule
end

function __fish_prompt_spinner_stop
    set -g __fish_prompt_spinner_active 0
    if set -q __fish_prompt_spinner_tick_pid
        and string match --quiet --regex '^[0-9]+$' -- "$__fish_prompt_spinner_tick_pid"
        set -l tick_pid $__fish_prompt_spinner_tick_pid
        command kill $tick_pid 2>/dev/null
        wait $tick_pid 2>/dev/null
        set -e __fish_prompt_spinner_tick_pid
    end
    return 0
end

function __fish_prompt_spinner_sync
    if __fish_prompt_spinner_needs_animation
        __fish_prompt_spinner_start
    else
        __fish_prompt_spinner_stop
    end
end

function __fish_prompt_spinner_schedule
    test "$__fish_prompt_spinner_active" = 1; or return
    set -q __fish_prompt_spinner_tick_pid; and return

    command sleep 0.15 &
    set -l tick_pid $last_pid
    set -g __fish_prompt_spinner_tick_pid $tick_pid
    set -l handler_name __fish_prompt_spinner_tick_$tick_pid

    function $handler_name --on-process-exit $tick_pid \
        --inherit-variable handler_name \
        --inherit-variable tick_pid
        functions -e $handler_name
        if set -q __fish_prompt_spinner_tick_pid
            and test "$__fish_prompt_spinner_tick_pid" = "$tick_pid"
            set -e __fish_prompt_spinner_tick_pid
        end

        test "$__fish_prompt_spinner_active" = 1; or return
        set -g __fish_prompt_spinner_frame \
            (math "$__fish_prompt_spinner_frame % "(count $__fish_prompt_spinner_frames)" + 1")
        set -g __fish_prompt_spinner_ticks (math "$__fish_prompt_spinner_ticks + 1")

        # 67 frames at 150 ms each is approximately a 10-second poll interval.
        if test (math "$__fish_prompt_spinner_ticks % 67") -eq 0
            and test "$__fish_prompt_pr_check_state" = pending
            and not set -q __fish_prompt_pr_worker_pid
            __fish_prompt_pr_request "$__fish_prompt_pr_current_key"
        end

        __fish_prompt_repaint
        __fish_prompt_spinner_schedule
    end
end

function __fish_prompt_repaint
    status is-interactive; or return
    set -q __fish_prompt_command_running; and return
    commandline --paging-mode; and return
    commandline --search-mode; and return
    commandline -f repaint 2>/dev/null
end

function __fish_prompt_pr_render
    set -l final_rendering "$argv[1]"
    if not set -q __fish_prompt_pr_cache_key
        or test "$__fish_prompt_pr_cache_key" != "$__fish_prompt_pr_current_key"
        or test -z "$__fish_prompt_pr_number"
        return
    end

    if not set -q __fish_prompt_spinner_frames
        set -g __fish_prompt_spinner_frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    end
    set -q __fish_prompt_spinner_frame; or set -g __fish_prompt_spinner_frame 1
    set -l frame $__fish_prompt_spinner_frames[$__fish_prompt_spinner_frame]

    if test "$final_rendering" -eq 1
        set_color brblack
    else
        set_color blue
    end
    printf "#%s" "$__fish_prompt_pr_number"

    if test "$final_rendering" -eq 1
        set_color brblack
    else
        switch "$__fish_prompt_pr_state"
            case merged
                set_color green
            case closed
                set_color red
            case '*'
                switch "$__fish_prompt_pr_check_state"
                    case pass
                        set_color green
                    case fail error
                        set_color red
                    case pending
                        set_color yellow
                    case '*'
                        set_color cyan
                end
        end
    end

    if test "$__fish_prompt_pr_is_draft" = true
        printf " draft"
    else
        switch "$__fish_prompt_pr_state"
            case merged
                printf " merged"
            case closed
                printf " closed"
            case '*'
                switch "$__fish_prompt_pr_check_state"
                    case pass
                        printf " ✓"
                    case fail
                        printf " ×"
                    case error
                        printf " ?"
                    case pending
                        printf " %s" "$frame"
                end
        end
    end
end

function __fish_prompt_commandline_is_blank
    if test (count $argv) -eq 0
        return 0
    end

    not string match --quiet --regex '\S' -- (string join \n -- $argv)
end

function __fish_prompt_accept_line
    if __fish_prompt_commandline_is_blank (commandline)
        set -g __fish_prompt_empty_submit 1
    else
        set -e __fish_prompt_empty_submit
    end

    commandline -f execute
end

function __fish_prompt_compact_empty --on-event fish_prompt
    if not set -q __fish_prompt_empty_submit
        return
    end

    set -e __fish_prompt_empty_submit
    printf "\033[2A\r\033[K\n"
end

function __fish_prompt_pause_animation --on-event fish_preexec
    set -g __fish_prompt_command_running 1
    __fish_prompt_spinner_stop
end

function space --on-event fish_postexec
    set -e __fish_prompt_command_running
    set -e __fish_prompt_context_cache_pwd
    set -e __fish_prompt_context_cache_value
    set -e __fish_prompt_context_cache_repository
    set -e __fish_prompt_context_cache_branch
    set -e __fish_prompt_context_cache_head
    set -e __fish_prompt_context_cache_is_github
    set -e __fish_prompt_title_context_cache_value
    set -e __fish_prompt_tag_cache_pwd
    set -e __fish_prompt_tag_cache_head
    set -e __fish_prompt_tag_cache_value
    set -e __fish_prompt_git_render_cache
    if string match --quiet --regex \
            '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+(create|close|reopen|merge)' \
            -- "$argv[1]"
        __fish_prompt_pr_clear
    end
    printf "\n\n"
end

function __clear_prompt_cache --on-variable PWD
    set -e __fish_prompt_pr_current_key
    __fish_prompt_pr_clear
    __fish_prompt_spinner_stop
    set -e __git_dir_cache_pwd
    set -e __git_dir_cache_value
    set -e __fish_prompt_context_cache_pwd
    set -e __fish_prompt_context_cache_value
    set -e __fish_prompt_context_cache_repository
    set -e __fish_prompt_context_cache_branch
    set -e __fish_prompt_context_cache_head
    set -e __fish_prompt_context_cache_is_github
    set -e __fish_prompt_title_context_cache_value
    set -e __fish_prompt_tag_cache_pwd
    set -e __fish_prompt_tag_cache_head
    set -e __fish_prompt_tag_cache_value
    set -e __fish_prompt_git_render_cache
end
