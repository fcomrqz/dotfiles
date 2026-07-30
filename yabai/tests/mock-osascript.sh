#!/bin/sh

set -eu

printf '%s\n' "$*" >>"${MOCK_YABAI_LOG:?MOCK_YABAI_LOG is required}"
