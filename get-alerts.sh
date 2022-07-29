#!/bin/bash
# DOT NOT REMOVE LEADING AND TRAILING SPACES
STATE_LIST=" OPEN FIXED DISMISSED "
if [ $# -lt "1" ]; then
    echo "Usage: $0 <reposfilename> [state]"
    echo "optional state can have the following values: $STATE_LIST"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "File $1 does not exist"
    exit 1
fi

filename="$1"
state="$2"

state_query_parameter=''
state_parameter=''

if [ "$state" != "" ]; then
    if ! [[ "$STATE_LIST" =~ (^|[[:space:]])$state($|[[:space:]]) ]]; then
        echo "state $state is not in the list of states. Use one of the following: $STATE_LIST"
        exit 1
    fi

    state_query_parameter=', $state: RepositoryVulnerabilityAlertState!'
    state_parameter=", states: $state"
fi

query='query($org: String! $repo: String! $endCursor: String){
repository(owner: $org, name: $repo) {
    vulnerabilityAlerts(first: 100, after: $endCursor '$state_parameter') {
        pageInfo {
            hasNextPage
            endCursor
        }
        nodes {
            repository {
                isArchived
            }
            id
            dependencyScope
            state
            securityVulnerability {
                package {
                    ecosystem
                    name
                }
                severity
                advisory {
                    cvss {
                        score
                    }
                }
            }
            dependabotUpdate {
                pullRequest {
                    number
                }
            }
        }
        }
    }
}'

echo "owner,repository,isArchived,state,id,fixedAt,dismissedAt,dismissedBy, dismissReason,scope,ecosystem,package,severity,cvssscore,pr"

while read -r repofull ; 
do
    IFS='/' read -ra data <<< "$repofull"

    org=${data[0]}
    repo=${data[1]}

    gh api graphql --paginate -F org="$org" -F repo="$repo" -f query="$query" | jq --arg owner "$org" --arg repo "$repo" -r '.data.repository.vulnerabilityAlerts.nodes[] 
        | [$owner, $repo, .repository.isArchived, .state, .id, .fixedAt, .dismissedAt, .dismisser.login, .dismissReason,
        .dependencyScope, .securityVulnerability.package.ecosystem, 
        .securityVulnerability.package.name, .securityVulnerability.severity, 
        .securityVulnerability.advisory.cvss.score, .dependabotUpdate.pullRequest.number ] | @csv'  

done < "$filename"

