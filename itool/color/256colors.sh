#!/bin/bash

function 256color ()
{
  for i in {0..255};
  do
    echo -e "\e[38;05;${i}m█${i}";
  done | column -c 180 -s ' ';
  echo -e "\e[m"
}

256color
