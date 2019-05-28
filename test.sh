#!/bin/sh

submission="$1"
pth="$(realpath "$submission")"

echo "$submission"
echo "$pth"

if [[ "$pth" != /home/sourcecode/* ]]; then
    echo "Error! Provided target of $submission doesn't exist in your home directory. Try again" 1>&2
fi
