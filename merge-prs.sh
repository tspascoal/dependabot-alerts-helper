#!/bin/bash

# DOT NOT REMOVE LEADING AND TRAILING SPACES
MERGE_METHOD_LIST=" merge squash rebase "

if [ $# -lt "1" ]; then
    echo "Usage: $0 <alertsfile> <message> [merge method]"
    echo "valid values for method are : merge squash rebase"
    echo "default value for merge method is 'merge'"
    exit 1
fi

filename="$1"
method="$2"

if [ "$method" == "" ]; then
    # set default merge method
    method="merge"
fi

if [ ! -f "$filename" ]; then
    echo "File $filename does not exist"
    exit 1
fi

if ! [[ "$MERGE_METHOD_LIST" =~ (^|[[:space:]])$method($|[[:space:]]) ]]; then
    echo "merge method $method is not in the list of supported merges. Use one of the following: $MERGE_METHOD_LIST"
    exit 1
fi

while read -r fields ; 
do

    IFS=',' read -ra data <<< "$fields"

    owner=${data[0]}
    repo=${data[1]}
    pr=${data[2]}

    if [ "$pr" == '' ] || [ "$pr" == "pr" ]; then
        continue
    fi

    prstatus=$(gh pr view -R "$owner/$repo" "$pr" --json state -q .state)

    if [ "$prstatus" != "OPEN" ]; then
        echo "PR $pr is $prstatus, skipping"
        continue
    fi
    
    echo Merging PR "$pr" in "$owner/$repo" with method "$method"
    gh pr merge --repo "$owner/$repo" "$pr" "--$method"

    # lets wait a little in case this PR would fix other prs
    sleep 10s

done <<< "$(csvtool -c 1,2,15 "$filename" | sort -u)"
