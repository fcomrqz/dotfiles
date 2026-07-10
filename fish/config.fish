if status --is-interactive
    # ------
    # direnv
    # ------
    set -x DIRENV_LOG_FORMAT ""
    # Homebrew provides this hook through vendor_conf.d. Keep a fallback for
    # installations that do not ship the vendor configuration.
    functions -q __direnv_export_eval; or direnv hook fish | source

    # --------
    # homebrew
    # --------
    fish_add_path /opt/homebrew/bin

    # ---
    # bun
    # ---
    set --export BUN_INSTALL "$HOME/.bun"
    fish_add_path --path --move $BUN_INSTALL/bin

    # --------
    # Orbstack
    # --------
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :

    # --------
    # Android
    # --------
    set -x ANDROID_HOME $HOME/Library/Android/sdk
    set -l java_home /Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
    if not test -d $java_home
        set java_home (/usr/libexec/java_home -v 17)
    end
    set -x JAVA_HOME $java_home

    fish_add_path $ANDROID_HOME/platform-tools
    fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
    fish_add_path $ANDROID_HOME/emulator
    fish_add_path $JAVA_HOME/bin

    # --------
    # env vars
    # --------
    if not set -q GH_TOKEN[1]; or test -z "$GH_TOKEN"
        set -Ux GH_TOKEN (gh auth token)
    end
    set -q EDITOR; or set -Ux EDITOR micro
    set -q BAT_THEME; or set -Ux BAT_THEME ansi
    set -q GEMINI_SANDBOX; or set -Ux GEMINI_SANDBOX true

    set -g fish_greeting

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
