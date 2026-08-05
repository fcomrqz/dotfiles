fish_add_path "$HOME/.local/bin"
set -gx LESSCHARSET utf-8

if test (uname) = Linux
    set -gx BUN_INSTALL "$HOME/.bun"
    fish_add_path "$BUN_INSTALL/bin"
    fish_add_path "$HOME/.fly/bin"
end

if status --is-interactive
    switch (uname)
        case Darwin
            fish_add_path /opt/homebrew/bin
            source ~/.orbstack/shell/init2.fish 2>/dev/null || :

            set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
            set -l java_home /Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
            if not test -d "$java_home"
                set java_home (/usr/libexec/java_home -v 17 2>/dev/null)
            end
            if test -n "$java_home"
                set -gx JAVA_HOME "$java_home"
                fish_add_path "$JAVA_HOME/bin"
            end
            fish_add_path "$ANDROID_HOME/platform-tools"
            fish_add_path "$ANDROID_HOME/cmdline-tools/latest/bin"
            fish_add_path "$ANDROID_HOME/emulator"
            set -gx EDITOR "zed --wait"
        case Linux
            set -gx EDITOR micro
    end

    set -g fish_greeting
    set -g fish_transient_prompt 1

    # ------
    # Colors
    # ------
    fish_config theme choose alavesper

    # -----------
    # Keybindings
    # -----------

    bind ctrl-o open_project
    bind ctrl-r open_history_search
    bind alt-\( kill-word
end
