#!/usr/bin/env fish

set root (path resolve (path dirname (status filename))/..)
source "$root/fish/functions/open_project.fish"

function fail
    printf 'not ok - %s\n' "$argv" >&2
    exit 1
end

set temporary_directory (mktemp -d)
set macos_root "$temporary_directory/Developer"
set primary "$macos_root/owner/repository"
set zed_checkout \
    "$macos_root/owner/worktrees/repository/zed-key/repository"
set codex_checkout \
    "$temporary_directory/.codex/worktrees/codex-key/repository"

command mkdir -p "$primary"
command git init --quiet --initial-branch main "$primary"
command git -C "$primary" config user.email test@example.com
command git -C "$primary" config user.name Test
printf 'initial\n' >"$primary/file"
command git -C "$primary" add file
command git -C "$primary" commit --quiet -m initial
command git -C "$primary" worktree add --quiet -b zed "$zed_checkout"
command git -C "$primary" worktree add --quiet -b codex "$codex_checkout"
set primary (path resolve "$primary")
set zed_checkout (path resolve "$zed_checkout")
set codex_checkout (path resolve "$codex_checkout")

set primary_repositories (
    __open_project_primary_repositories "$macos_root" Darwin
)
test (count $primary_repositories) -eq 1
or fail "macOS discovery finds only primary clones"
test "$primary_repositories[1]" = "$primary"
or fail "macOS discovery supports GitHub owner folders"

__open_project_collect_checkouts "$macos_root" Darwin
test (count $__open_project_checkout_paths) -eq 3
or fail "registered primary, Zed, and Codex checkouts are collected"

set primary_index (
    contains --index -- "$primary" $__open_project_checkout_paths
)
set zed_index (
    contains --index -- "$zed_checkout" $__open_project_checkout_paths
)
set codex_index (
    contains --index -- "$codex_checkout" $__open_project_checkout_paths
)
test -n "$primary_index"
and test -n "$zed_index"
and test -n "$codex_index"
or fail "all checkout paths remain selectable"

__open_project_describe \
    "$primary" \
    "$__open_project_repository_names[$primary_index]" \
    Darwin
string match --quiet --regex '^repository main [0-9a-f]{7}$' \
    "$__open_project_plain_description"
or fail "primary checkout omits the worktree field"
set primary_activity $__open_project_activity

__open_project_describe \
    "$zed_checkout" \
    "$__open_project_repository_names[$zed_index]" \
    Darwin
string match --quiet --regex '^repository zed [0-9a-f]{7}$' \
    "$__open_project_plain_description"
or fail "Zed worktrees omit their generated name"

__open_project_describe \
    "$codex_checkout" \
    "$__open_project_repository_names[$codex_index]" \
    Darwin
string match --quiet --regex '^repository codex [0-9a-f]{7}$' \
    "$__open_project_plain_description"
or fail "Codex worktrees omit their generated key"

command git -C "$zed_checkout" checkout --quiet --detach
__open_project_describe \
    "$zed_checkout" \
    "$__open_project_repository_names[$zed_index]" \
    Darwin
string match --quiet --regex '^repository @[0-9a-f]{7}$' \
    "$__open_project_plain_description"
or fail "detached branches use the commit in place of a branch"

printf 'changed\n' >>"$zed_checkout/file"
command touch -t 203001010101 "$zed_checkout/file"
__open_project_describe \
    "$zed_checkout" \
    "$__open_project_repository_names[$zed_index]" \
    Darwin
string match --quiet --regex '^repository @[0-9a-f]{7} \*$' \
    "$__open_project_plain_description"
or fail "dirty status is displayed"
test "$__open_project_activity" -gt "$primary_activity"
or fail "working-tree edits determine recent-first ordering"

set linux_root "$temporary_directory/linux"
set linux_repository "$linux_root/repository"
command mkdir -p "$linux_repository"
command git init --quiet --initial-branch main "$linux_repository"
set linux_repository (path resolve "$linux_repository")
set linux_repositories (
    __open_project_primary_repositories "$linux_root" Linux
)
test "$linux_repositories[1]" = "$linux_repository"
or fail "Linux discovery uses direct home-directory clones"

command rm -rf "$temporary_directory"

printf 'ok - open_project discovers OS clone roots and registered worktrees\n'
printf 'ok - open_project formats repo, branch, commit, and status\n'
printf 'ok - open_project sorts current edits ahead of older commits\n'
