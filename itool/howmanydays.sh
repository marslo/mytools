#!/usr/bin/env bash
# shellcheck disable=SC1078,SC1079,SC2164,SC2046

# =============================================================================
#   FileName: howmanydays.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2020-06-01 19:37:44
# LastChange: 2020-06-01 19:37:44
# =============================================================================

usage="""USAGE:
\n\t$0 YYYY-MM-DD
\nExample:
\n\t$0 1987-03-08
\n\t$ date
\tMon Jun  1 19:39:29 CST 2020
\t\$ $0 2020-01-01
\t152 days
"""

if [ 1 -ne $# ]; then
  echo -e "${usage}"
else
  if date +%s --date "$1" > /dev/null 2>&1; then
    echo $((($(date +%s)-$(date +%s --date "$1"))/(3600*24))) days
  else
    echo -e "${usage}"
  fi
fi
