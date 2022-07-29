#!/bin/bash

# DOT NOT REMOVE LEADING AND TRAILING SPACES
REASON_LIST=" FIX_STARTED INACCURATE NOT_USED NO_BANDWIDTH TOLERABLE_RISK "

if [ $# -ne "2" ]; then
    echo "Usage: $0 <alertsfile> <reason>"
    echo "reason can be one of : $REASON_LIST"
    exit 1
fi

filename="$1"
reason="$2"

if ! [[ "$REASON_LIST" =~ (^|[[:space:]])$reason($|[[:space:]]) ]]; then
    echo "reason $reason is not in the list of reasons : $REASON_LIST"
    exit 1
fi

if [ ! -f "$filename" ]; then
    echo "File $filename does not exist"
    exit 1
fi

while read -r id ; 
do

if [ "$id" == "id" ]; then
    continue
fi
echo Dismissing "$id"

gh api graphql --paginate -F id="$id" -F reason="$reason"  -f query='mutation($id: ID!, $reason: DismissReason!)  {
  dismissRepositoryVulnerabilityAlert(input:{repositoryVulnerabilityAlertId:$id,dismissReason: $reason}) {
    repositoryVulnerabilityAlert {
      id
    }
  }
}'

done <<< "$(csvtool -c 5 "$filename")"
