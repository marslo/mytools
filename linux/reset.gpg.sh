#!/usr/bin/env bash

# source ~/.profile
systemctl --user import-environment
gpgconf --kill all 
pkill gpg-agent 
gpgconf --kill all
gpg --card-status
