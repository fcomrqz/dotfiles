#!/usr/bin/env fish

set root (path resolve (path dirname (status filename))/..)
source "$root/fish/functions/fish_prompt.fish"

function fail
    printf 'not ok - %s\n' "$argv" >&2
    exit 1
end

__fish_prompt_commandline_is_blank
or fail "empty command line is blank"

__fish_prompt_commandline_is_blank '   ' \t
or fail "whitespace-only command line is blank"

if __fish_prompt_commandline_is_blank "echo 'hello'" "echo 'bye'"
    fail "multiline command is not blank"
end

if __fish_prompt_commandline_is_blank "echo 'hello'"
    fail "single-line command is not blank"
end

function git
    switch "$argv[1]"
        case status
            printf '%s\n' \
                '# branch.oid 0123456789abcdef' \
                '# branch.head main' \
                '# branch.upstream origin/main' \
                '# branch.ab +7 -2'
        case rev-parse describe
            return 1
    end
end

set git_status (__fish_prompt_git_status)
functions --erase git

string match --quiet '*↓*' "$git_status"
or fail "behind commits are rendered"
string match --quiet '*↑*' "$git_status"
or fail "ahead commits are rendered"

set original_directory $PWD
set temporary_directory (mktemp -d)
set primary_repository "$temporary_directory/repository"
set linked_repository "$temporary_directory/worktrees/repository/topic/repository"

test (__fish_prompt_display_path "$HOME") = '~'
or fail "home directory is abbreviated"
test (__fish_prompt_display_path "$HOME/example/path") = '~/example/path'
or fail "paths below home are abbreviated"
test (__fish_prompt_display_path "$temporary_directory") = "$temporary_directory"
or fail "paths outside home remain absolute"

command mkdir -p "$primary_repository" (path dirname "$linked_repository")
command git init --quiet --initial-branch main "$primary_repository"
command git -C "$primary_repository" config user.email test@example.com
command git -C "$primary_repository" config user.name Test
printf 'test\n' >"$primary_repository/file"
command git -C "$primary_repository" add file
command git -C "$primary_repository" commit --quiet -m initial
command git -C "$primary_repository" worktree add --quiet -b feature "$linked_repository"

cd "$primary_repository"
__clear_prompt_cache
set primary_context (__fish_prompt_command_context)
set primary_title (fish_prompt --title-context)
string match --quiet '*repository main *' "$primary_context"
or fail "primary checkout repository and branch are rendered"
switch (uname)
    case Darwin
        if string match --quiet '**' "$primary_context" "$primary_title"
            fail "macOS prompt and title omit the Apple symbol"
        end
    case Linux
        string match --quiet '⌁ *' "$primary_context"
        or fail "Linux prompt retains its symbol"
        string match --quiet '⌁*' "$primary_title"
        or fail "Linux title retains its symbol"
end

cd "$linked_repository"
__clear_prompt_cache
set linked_context (__fish_prompt_command_context)
set linked_title (fish_prompt --title-context)
string match --quiet '*repository feature *' "$linked_context"
or fail "linked worktree prompt renders repository and branch"
string match --quiet '*repository*feature' "$linked_title"
or fail "linked worktree title renders repository and branch"
if string match --quiet '*topic*' "$linked_context" "$linked_title"
    fail "linked worktree prompt and title omit the worktree name"
end

cd "$temporary_directory"
__clear_prompt_cache
set directory_context (__fish_prompt_command_context)
set directory_title (fish_prompt --title-context)
string match --quiet "*$temporary_directory" "$directory_context"
or fail "non-repository prompt renders the full path"
string match --quiet "*$temporary_directory" "$directory_title"
or fail "non-repository title renders the full path"

cd "$original_directory"
command rm -rf "$temporary_directory"

printf 'ok - prompt accepts multiline commands\n'
printf 'ok - prompt parses ahead and behind counts\n'
printf 'ok - prompt renders repository and branch without worktree names\n'
printf 'ok - prompt applies platform symbols\n'
printf 'ok - prompt renders abbreviated full paths outside repositories\n'
