#!/bin/zsh

qmk config user.keyboard=wilba_tech/wt60_h1
qmk config user.keymap=fcomrqz

ln -sF ~/Developer/fcomrqz/dotfiles/qmk/wt60 ~/qmk_firmware/keyboards/wilba_tech/wt60_h1/keymaps/fcomrqz

qmk flash
