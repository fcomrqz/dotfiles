#!/bin/zsh

qmk config user.keyboard=boardsource/unicorne
qmk config user.keymap=fcomrqz

ln -sF ~/Developer/fcomrqz/dotfiles/qmk/unicorne ~/qmk_firmware/keyboards/boardsource/unicorne/keymaps/fcomrqz

qmk flash
