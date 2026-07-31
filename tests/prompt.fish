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

printf 'ok - prompt accepts multiline commands\n'
