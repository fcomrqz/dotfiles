# Dotfiles

Scripts to install apps and configure dotfiles for setting up my preferred macOS environment.
[Learn more about dotfiles and how I build mine](https://fcomrqz.com/dotfiles).

I perform a clean macOS install 1-3 times a year, typically after major Apple releases or when my machine starts behaving buggy.

Previously, this process was manual and time-consuming, taking up to a full day. With this scripts, the setup time has been reduced to 2-4 hours, depending on internet speed, and requires zero clicks.

## Instructions

1. Backup your current Terminal themes.

2. Download the latest macOS installer:
    ```sh
    softwareupdate --fetch-full-installer --full-installer-version 15.0
    ```

3. Create a new disk volume for the fresh install.

4. Install macOS and complete setup assistant.

5. Install Command Line Tools for Xcode:
    ```sh
    xcode-select --install
    ```
6. Install Command Line Tools for Xcode:
    ```sh
    sudo xcodebuild -license
    ```
    _You will be asked for your macOS login password._
7. Run the following commands in your terminal to download this repo, install [all my preferred apps](https://fcomrqz.com/tools#macOS), and set up my custom preferences:
    ```sh
    mkdir -p ~/Developer/fcomrqz
    cd ~/Developer/fcomrqz
    git clone https://github.com/fcomrqz/dotfiles
    cd dotfiles
    bash install.sh
    ```
    _You will be asked for your macOS login password._
