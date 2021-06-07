#!/usr/bin/env bash

main() {
  for (( i = 0; i <= 100; i=$i + 1)); do
    progress_bar "$i"
    sleep 0.1;
  done
  progress_bar "done"
  exit 0
}

progress_bar() {
  if [ "$1" == "done" ]; then
    spinner="X"
    percent_done="100"
    progress_message="Done!"
    new_line="\n"
  else
    spinner='/-\|'
    percent_done="${1:-0}"
    progress_message="$percent_done %"
  fi

  percent_none="$(( 100 - $percent_done ))"
  [ "$percent_done" -gt 0 ] && local done_bar="$(printf '#%.0s' $(seq -s ' ' 1 $percent_done))"
  [ "$percent_none" -gt 0 ] && local none_bar="$(printf '~%.0s' $(seq -s ' ' 1 $percent_none))"

  # print the progress bar to the screen
  printf "\r Progress: [%s%s] %s %s${new_line}" \
    "$done_bar" \
    "$none_bar" \
    "${spinner:x++%${#spinner}:1}" \
    "$progress_message"
}

main "$@"
