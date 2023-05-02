#!/bin/sh
export SALSIFY_LINE_SERVER_FILE=$1

if [ -z "$1" ]
then
  echo "No filename passed"
else
  if [ -f "./$SALSIFY_LINE_SERVER_FILE" ]
  then
      echo "text file '$SALSIFY_LINE_SERVER_FILE' found, starting application."
      bundle exec rackup -p 3000
  else
      echo "text file '$SALSIFY_LINE_SERVER_FILE' not found. Please check filename and try again."
  fi
fi
