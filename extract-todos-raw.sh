#! /bin/bash

set -o pipefail
trap 'catch $? $LINENO' EXIT

catch() {
  if [ "$1" != "0" ]; then
    printf "\nThere was an error running the script. Apologies — please get in touch with us at support@stepsize.com so we can look into it.\n"
  fi
}

printf "Searching for todos...\n"

# Find files with TODOs in them, -I skips binaries
files_with_todos=$(git grep -l -I TODO)

# Exit if no TODOs are found
if ! [ "$files_with_todos" ]; then printf "\nNo TODO comments were found in this repository.\n"; exit 0; fi

# Set the default separator to new line so that we can look through lines
# rather than whitespace
IFS=$'\n'

output=""

# Loop through each of the files
for f in $files_with_todos
do
  # Get each todo comment
  todos=$(git grep -n TODO -- "$f")

  # Loop through each TODO
  for t in $todos
  do
    text=$(echo "$t" | sed 's/^.*TODO:* *\(.*\)$/\1/')
    text_escaped=$(echo "$text" | sed "s/\\\n/\\\\\\\\\n/g")

    output="${output}${text_escaped}\n"
  done
done

# Copy output to clipboard
__IS_MAC=${__IS_MAC:-$(test $(uname -s) == "Darwin" && echo 'true')}
if [ -n "${__IS_MAC}" ]; then
  printf $output | /usr/bin/pbcopy
else
  # If xclip is installed
  if command -v xclip &> /dev/null
  then
    printf $output | xclip -i -sel c -f | xclip -i -sel p
  else
    # If clip.exe is installed
    if command -v clip.exe
    then
      printf $output | clip.exe
    else
      printf "\nThis script requires xclip or clip.exe.\n"
      exit 0
    fi
  fi
fi

printf "\nraw TODO comments are now in your clipboard\n\n"
printf "Thank you for using Stepsize!\n"
