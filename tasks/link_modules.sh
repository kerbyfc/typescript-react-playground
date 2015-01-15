#!/bin/bash

# project directory
cwd=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd );

# filenames
classpath_file="vertx_classpath.txt"
link_file="module.link"

# modules to be linked by vertx
mods=($(find `pwd` -name .classpath))

for mod in "${mods[@]}"
do
  dir=($(dirname $mod))
  paths=($(cat $mod))

  # cleanup vertx_classpath.txt
  echo '' > "$dir/$classpath_file"

  # setup module classpath
  for path in "${paths[@]}"
  do
    echo "$dir/$path" >> "$dir/$classpath_file"
  done

  # link module
  echo $dir > "$dir/$link_file"

  echo "[ linked ] $dir"
done
