#! /bin/bash

# Exit 1 if script is run from a non git repository
if ! [ -d .git ]; then
  printf "\nERROR: Script failed to run. This script only works within Git repositories.\n";
  exit 1
fi;

# Get required repository metadata
remote_url=$(git ls-remote --get-url)
repo_name=$(basename "$remote_url" .git)
commit_hash=$(git rev-parse --short HEAD)

# Get required user metadata
user_name=$(git config user.name)
user_email=$(git config user.email)

# Exit 1 if user metadata can't be found
if ! [ "$user_name" ] || ! [ "$user_email" ]; then
  printf "\nUser information could not be found. Please contact us on support@stepsize.com.\n";
  exit 1
fi;

output="repo_name,remote_url,commit_hash,user_name,user_email\n"
output="${output}${repo_name},${remote_url},${commit_hash},${user_name},${user_email}\n\n"

output="${output}file_path,line,commit_hash,author_name,author_email,commit_date,text\n"

# Find files with TODOs in them, -I skips binaries
files_with_todos=$(git grep -l -I TODO)

# Exit 0 if no TODOs are found
if ! [ "$files_with_todos" ]; then
  printf "\nNo TODO comments were found in this repository.\n";
  exit 0
fi;

# Set the default separator to new line so that we can look through lines
# rather than whitespace
IFS=$'\n'

# Loop through each of the files
for f in $files_with_todos
do
  # Get each todo comment
  todos=$(git grep -n TODO -- "$f")

  # Loop through each TODO
  for t in $todos
  do
    line_number=$(echo "$t" | sed 's/^[^:]*:\([^:]*\):.*$/\1/')
    text=$(echo "$t" | sed 's/^.*TODO:* *\(.*\)$/\1/')
    line_commit_hash=$(git blame -L$line_number,+1 -- "$f" | awk '{print $1;}')

    # Skip uncommitted lines
    if [ "$line_commit_hash" = "000000000" ]; then continue; fi

    author_and_date=$(git log $line_commit_hash -1 --pretty=format:'%an,%ae,%ai')

    output="${output}${f},${line_number},${line_commit_hash},${author_and_date},'${text}'\n"
  done
done

# Copy output to clipboard
__IS_MAC=${__IS_MAC:-$(test $(uname -s) == "Darwin" && echo 'true')}
if [ -n "${__IS_MAC}" ]; then
  printf $output | /usr/bin/pbcopy
else
  printf $output | xclip -i -sel c -f | xclip -i -sel p
fi

printf "\nTODO comments are now in your clipboard, please paste them into a text field on the Import page in Stepsize web app.\n\n"
printf "Thank you for using Stepsize!\n"