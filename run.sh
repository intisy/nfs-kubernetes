#!/bin/bash

action=$1
pat=$2
arg=$3

execute() {
  substring="#!/bin/bash"
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/nfs-kubernetes/commits | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/nfs-kubernetes/$sha/scripts/$action.sh"
  echo "Executing: $url"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring ]]; then
    if [ -n "$pat" ]; then
      curl -X GET -H "Authorization: Bearer $pat" -H "Content-Type: application/json" -fsSL $url | bash -s $arg
    else
      curl -fsSL $url | bash -s $arg
    fi
  else
    sleep 1
    execute
  fi
}
execute
