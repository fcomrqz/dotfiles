#!/bin/bash
echo ''
printf "\033[1;34mEnter your tokens\033[0m\n"
read -p 'GitHub Token: ' MY_GITHUB_TOKEN
read -p 'Postmark Account Token: ' POSTMARK_ACCOUNT_TOKEN
read -p 'Postmark Server Token: ' POSTMARK_SERVER_TOKEN
export MY_GITHUB_TOKEN=$MY_GITHUB_TOKEN
export POSTMARK_ACCOUNT_TOKEN=$POSTMARK_ACCOUNT_TOKEN
export POSTMARK_SERVER_TOKEN=$POSTMARK_SERVER_TOKEN
sudo -v

