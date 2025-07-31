#!/bin/zsh

qmk config user.keyboard=boardsource/unicorne
qmk config user.keymap=fcomrqz

ln -sF ~/Developer/fcomrqz/dotfiles/qmk/unicorne/keymap.c ~/qmk_firmware/keyboards/boardsource/unicorne/keymaps/fcomrqz/
ln -sF ~/Developer/fcomrqz/dotfiles/qmk/unicorne/config.h ~/qmk_firmware/keyboards/boardsource/unicorne/keymaps/fcomrqz/
ln -sF ~/Developer/fcomrqz/dotfiles/qmk/unicorne/rules.mk ~/qmk_firmware/keyboards/boardsource/unicorne/keymaps/fcomrqz/

qmk flash
