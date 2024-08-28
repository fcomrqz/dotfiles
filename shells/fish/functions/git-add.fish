function git-add
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        promptError "Not git directory"
        return 1
    end

    if git diff --quiet --exit-code && test -z "$(git ls-files --exclude-standard --others)"
        promptError "Clean working directory"
        return 1
    end

    set -l dirty_files (git status -s | grep '^.[M?RCDU]')
    set -l dirty_files_height (math (count $dirty_files) + 3)

    # Get terminal height
    set -l term_height_total (tput lines)

    set -l gum_height
    if test $dirty_files_height -gt $term_height_total
        set gum_height $term_height_total
    else
        set gum_height $dirty_files_height
    end

    # Ensure gum_height is at least 1 and at most term_height_total - 1
    set gum_height (math "max(1, min($gum_height, $term_height_total - 2))")

    set -l files (printf '%s\n' $dirty_files | sed 's/^ M/\x1b[33m*\x1b[0m/;s/^MM/\x1b[33m*\x1b[0m/;s/^AM/\x1b[33m*\x1b[0m/;s/^UU/\x1b[33m*\x1b[0m/;s/^??/\x1b[32m+\x1b[0m/;s/^ D/\x1b[31m-\x1b[0m/;s/^MD/\x1b[31m-\x1b[0m/;s/^R[M ]/\x1b[36m*\x1b[0m/;s/^AD/\x1b[32m+\x1b[0m/;s/^RD/\x1b[36m*\x1b[0m/;s/ -> /\x1b[36m → \x1b[0m/' | gum choose --no-limit --cursor="→ " --unselected-prefix="  " --header="" --cursor.foreground 2 --no-show-help --selected.foreground 4 --height $gum_height)

    if test -z "$files"
        commandline -f repaint
        return 1
    end

    for file in $files
        set -l clean_file (echo $file | sed -E 's/\x1B\[[0-9;]*[mK]//g' | sed -E 's/^[ *+-]+//')
        set -l clean_file (string trim "$clean_file")
        if test -n "$clean_file"
            if string match -q "*→*" "$clean_file"
                set -l new_file (string split "→" "$clean_file")[2]
                set -l new_file (string trim "$new_file")
                git add "$new_file" 2>/dev/null
            else
                git add "$clean_file" 2>/dev/null
            end
        end
    end

    commandline -f repaint
end
