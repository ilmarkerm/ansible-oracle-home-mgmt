#!/bin/bash

for db in `$1/bin/srvctl config database`; do
  outp=$($1/bin/srvctl config database -d $db | grep -i "Oracle home: $1")
  if [ -n "$outp" ]; then
    echo "$db is using $1"
    exit 1
  fi
done
