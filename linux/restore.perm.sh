#!/bin/bash
# credit: https://unix.stackexchange.com/a/128499/29178

while read -rd $'\n' perms user group file; do
  if [ -e "$file" ]; then
    chown "$user:$group" "$file"
    chmod "$perms" "$file"
  else
    echo "warning: $file not found"
  fi
done < file.perm.txt
