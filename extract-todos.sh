#! /bin/bash

printf "\nChecking if ${PWD##*/} is a Git repository..."

# Exit if script is run from a non git repository
if ! [ -d .git ]; then printf "\nThis script only works within Git repositories.\n"; exit 0; fi

# Get required repository metadata
remote_url=$(git ls-remote --get-url)
if ! [ "$remote_url" ]; then printf "\nRemote URL not found.\n"; exit 0; fi

repo_name=$(basename "$remote_url" .git)

commit_hash=$(git rev-parse --short HEAD)
if ! [ "$commit_hash" ] ; then printf "\nCommit hash not found.\n"; exit 0; fi

# Get user.name metadata
user_name=$(git config user.name)
if ! [ "$user_name" ] ; then printf "\nGit user.name not found. Please set it using 'git config user.name \"<your name>\"'\n"; exit 0; fi

# Get user.email metadata
user_email=$(git config user.email)
if ! [ "$user_email" ]; then printf "\nGit user.email not found. Please set it using 'git config user.email \"<your email>\"'\n"; exit 0; fi

output="repo_name,remote_url,commit_hash,user_name,user_email\n"
output="${output}${repo_name},${remote_url},${commit_hash},${user_name},${user_email}\n\n"

output="${output}file_path,line,commit_hash,author_name,author_email,commit_date,text\n"

printf "Searching for todos...\n"

# Find files with TODOs in them, -I skips binaries
files_with_todos=$(git grep -l -I TODO)

# Exit if no TODOs are found
if ! [ "$files_with_todos" ]; then printf "\nNo TODO comments were found in this repository.\n"; exit 0; fi

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
    text_escaped=$(echo "$text" | sed "s/\\\n/\\\\\\\\\n/g")
    line_commit_hash=$(git blame -L$line_number,+1 -- "$f" | awk '{print $1;}')

    # Skip uncommitted lines
    if [ "$line_commit_hash" = "000000000" ]; then continue; fi

    author_and_date=$(git log $line_commit_hash -1 --pretty=format:'%an,%ae,%ai')

    output="${output}${f},${line_number},${line_commit_hash},${author_and_date},'${text_escaped}'\n"
  done
done

# Copy output to clipboard
__IS_MAC=${__IS_MAC:-$(test $(uname -s) == "Darwin" && echo 'true')}
if [ -n "${__IS_MAC}" ]; then
  printf $output | /usr/bin/pbcopy
else
  printf $output | xclip -i -sel c -f | xclip -i -sel p
fi

printf "\nTODO comments are now in your clipboard, please paste them into the text field on app.stepsize.com/import/tool \n\n"
printf "Thank you for using Stepsize!\n"
