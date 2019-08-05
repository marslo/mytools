#!/bin/bash
# credit: https://unix.stackexchange.com/a/128501/29178

find . -printf 'chown -v %u:%g %p\n' > chowns.sh
find . -printf 'chmod -v %m %p\n' > chmods.sh
