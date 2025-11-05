# Dotfiles

Scripts to install apps and configure dotfiles for setting up my preferred macOS environment.
[Learn more about dotfiles and how I build mine](https://fcomrqz.com/dotfiles).

I perform a clean macOS install 1-3 times a year, typically after major or minor Apple releases.

Previously, this process was manual and time-consuming, taking up to a full day. With these scripts, the setup time has been reduced to 2-4 hours, depending on internet speed, and requires zero clicks.

## Instructions

1. List macOS installers:
    ```sh
    softwareupdate --list-full-installers
    ```

2. Download the latest macOS installer:
    ```sh
    softwareupdate --fetch-full-installer --full-installer-version X.X.X
    ```

3. Create a new disk volume for the fresh install using Disk Utility.

4. Install macOS and complete setup assistant.

5. Install Command Line Tools for Xcode:
    ```sh
    xcode-select --install
    ```

6. Install [Karabiner DriverKit VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/tree/main) following the instructions provided in the repository.

7. Run the following commands in your terminal to download this repo, install [all my preferred apps](https://fcomrqz.com/tools#macOS), and set up my custom preferences:
    ```sh
    mkdir -p ~/Developer/fcomrqz
    cd ~/Developer/fcomrqz
    git clone https://github.com/fcomrqz/dotfiles
    cd dotfiles
    bash install.sh
    ```
    _You will be asked for your macOS login password._
