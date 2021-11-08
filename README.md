# Dotfiles

Scripts and dotfiles to install apps and setup my preferences in macOS.
[What are dotfiles and How I build my own?](https://fcomrqz.com/dotfiles)

When Apple releases a new major version or my machine starts to behave buggy I do a clean macOS install. Max 1-3 times in a year.

Before this solution I was using a note to track the required steps to do a clean install. **Making it manually was taking me a whole day**.

**Now with this little project and without my attention** I can make it **in 2-4 hrs**.
_Internet speed will determine how long takes._

## Instructions

1. Make a macOS clean install:

   1. Check if your backups are updated.
   1. Shutdown your Mac.
   1. Turn on your Mac and immediately press and hold **Command (⌘)-R** until you see an Apple logo.
   1. Use Disk Utility to erase your disk.
   1. Install macOS.
   1. Finish the setup assistant process.

2. Run the next command in your terminal to download this repo, install [all the apps I use](https://fcomrqz.com/tools#macOS) and setup my preferences.
   _You will be asked for your GitHub token and macOS login password._

```sh
git clone https://github.com/fcomrqz/dotfiles && cd dotfiles && bash install.sh
```
