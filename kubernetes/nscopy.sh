#!/usr/bin/env bash

for ns in $(kubectl get ns -o custom-columns=":metadata.name" --no-headers | /usr/bin/grep 'ci-builder'); do
  declare project=$(echo ${ns} | awk -F'-' '{print $1}')
  declare newNS="${project}-builder"
  echo -e "\n${ns} : ${newNS}"
  echo "  hints: $ kubectl create namespace ${newNS}"
  echo "  hints: $ kubectl label namespace ${newNS} name=${newNS} --overwrite=true"

  for _r in $(kubectl api-resources --verbs=list --namespaced -o name); do
    if [[ 'No resources found.' != "$(kubectl get -n ${ns} ${_r} 2>&1 >/dev/null)" ]]; then
      echo "  - ${_r}"
      if [[ 'secrets' = "${_r}" || 'serviceaccounts' = "${_r}" ]]; then
        for _name in $(kubectl -n ${ns} get ${_r} -o custom-columns=":metadata.name" --no-headers); do
          echo "    hints: $ kubectl -n ${ns} get ${_r} ${_name} -o yaml --export | kubectl apply -n ${newNS} -f -"
        done
      else
        echo "    hints: $ kubectl -n ${ns} get ${_r} -o yaml --export | kubectl apply -n ${newNS} -f -"
      fi
    fi
  done
done
