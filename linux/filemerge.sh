#!/usr/bin/env bash
# shellcheck disable=SC1078,SC1079,SC2046

base=$1
contrast=$2
patchdiff='./p.txt'
[ -f "${patchdiff}" ] && rm -rf "${patchdiff}"

usage="""USAGE:
\n\t$0 [help] <file1> <file2>
\nNOTICE:
\t<file1> is the base file. the additional content in <file2> will merge into <file1> (fully covered).
\tMake sure <file1> has been backed up before all dangerous migration.
"""

function mergeDiff() {
  minusNum=$(diff -rupP "${base}" "${contrast}" | sed -n -re '/^-/{=;}' | grep -c -vE '1|2|3')
  finalNum=$(echo $(diff -rupP "${base}" "${contrast}" | sed -n -re 's:^@@.*,.*,(.).*@@$:\1:p') + "${minusNum}" | bc)

  diff -rupP --color=never "${base}" "${contrast}" | sed -re '3,$s:^-: :' | sed -re "s:(^@@.*,.*,)(.)(.*@@$):\1$finalNum\3:" > "${patchdiff}"
  echo -e "\n~~> original base file (${base}):"
  cat "${base}"
  patch "${base}" < "${patchdiff}"
  echo -e "\n~~> new base file (${base}):"
  cat "${base}"
}

function showDiff() {
  echo -e "\n~~> difference between ${base} and ${contrast}:"
  diff --side-by-side --color=always "${base}" "${contrast}"
}

function noDiff() {
  showDiff
  if [ 0 -eq $(diff -u "${base}" "${contrast}" | sed -n -re '/^\+[^\+].*$/=' | grep -c -vE '1|2|3') ]; then
    echo -e "\n~~> ${base} has alrady cover all contents in ${contrast}. No need merge anymore.\nExit"
    exit 0
  fi
}

function help() {
  echo -e "${usage}"
}


if [ "$1" = "help" ]; then
  help
else
  if [ $# -ne 2 ]; then
    help
  else
    noDiff
    mergeDiff
  fi
fi
