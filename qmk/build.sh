#!/bin/zsh

qmk config user.keyboard=wilba_tech/wt60_h1
qmk config user.keymap=fcomrqz

ln -sF ~/Developer/fcomrqz/dotfiles/qmk/keymap.c ~/qmk_firmware/keyboards/wilba_tech/wt60_h1/keymaps/fcomrqz/
ln -sF ~/Developer/fcomrqz/dotfiles/qmk/config.h ~/qmk_firmware/keyboards/wilba_tech/wt60_h1/keymaps/fcomrqz/
ln -sF ~/Developer/fcomrqz/dotfiles/qmk/rules.mk ~/qmk_firmware/keyboards/wilba_tech/wt60_h1/keymaps/fcomrqz/

qmk flash
