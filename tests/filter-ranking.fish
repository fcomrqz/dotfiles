#!/usr/bin/env fish

set repository_root (path resolve (path dirname (status filename))/..)
source "$repository_root/fish/functions/__gum_filter.fish"

function assert_equal --argument-names expected actual description
    if test "$expected" != "$actual"
        printf 'not ok - %s\n  expected: %s\n  actual:   %s\n' \
            "$description" "$expected" "$actual" >&2
        return 1
    end
    printf 'ok - %s\n' "$description"
end

set failures 0

__gum_filter_rank tk "The Black Knight" task toolkit
assert_equal \
    "The Black Knight|task|toolkit" \
    (string join '|' $__gum_filter_ranked_values) \
    "v0.1.1 fuzzy ranking and separator bonuses"
or set failures (math "$failures + 1")
assert_equal \
    "1,11;1,4;1,5" \
    (string join ';' $__gum_filter_ranked_indexes) \
    "matched indexes are retained for highlighting"
or set failures (math "$failures + 1")

__gum_filter_rank pro alpha-project project-alpha Product
assert_equal \
    "Product|project-alpha|alpha-project" \
    (string join '|' $__gum_filter_ranked_values) \
    "prefix and first-character bonuses"
or set failures (math "$failures + 1")

__gum_filter_rank "" first second third
assert_equal \
    "first|second|third" \
    (string join '|' $__gum_filter_ranked_values) \
    "empty query preserves input order"
or set failures (math "$failures + 1")

__gum_filter_rank mañ mañana gamma
assert_equal \
    "mañana" \
    (string join '|' $__gum_filter_ranked_values) \
    "UTF-8 queries work with macOS awk"
or set failures (math "$failures + 1")

assert_equal \
    "a" \
    (printf 'a' | __gum_filter_read_key; and printf '%s' "$__gum_filter_key") \
    "printable input uses the built-in reader"
or set failures (math "$failures + 1")

assert_equal \
    "ñ" \
    (printf 'ñ' | __gum_filter_read_key; and printf '%s' "$__gum_filter_key") \
    "the built-in reader preserves UTF-8 characters"
or set failures (math "$failures + 1")

printf '\n' | __gum_filter_read_key
assert_equal \
    '\n' \
    (string escape -- "$__gum_filter_key") \
    "the built-in reader preserves Enter"
or set failures (math "$failures + 1")

exit $failures
