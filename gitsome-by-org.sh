#!/bin/bash
# GraphQL Query to pull repository info from GitHub.com's Public API
# Reqs: curl, jq, Github Token in GITHUB_TOKEN env var
#
# Usage: ./$0 owner repository
# Example: ./gitsome-by-repo.sh facebook graphql
# to enumerate information for https://github.com/facebook/graphql
# todo: allow-list for safe characters only

# Org or user that owns the repo, default to thesavant42/gitsome
orgName="${1:-thesavant42}"

# Exit if GITHUB_TOKEN is not set
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Must provide GITHUB_TOKEN in environment" 1>&2
    exit 1
fi

# GraphQL Request to GitHub.com's API
data=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -s -d @- https://api.github.com/graphql << GQL
{ "query": "
  query {
    repositoryOwner(login: \"$orgName\") {
      ... on Organization {
        repositories(first: 100) {
          totalCount
          pageInfo {
            endCursor
            hasNextPage
          }
          nodes {
            id
            name
            stars: stargazerCount
            forks: forkCount
            created_at: createdAt          
            organization: owner {
              login
            }
            repo_url: url
          }
        }
      }
    }
  }
"}
GQL
)

## Uncomment out this next line to save the JSON
echo $data | jq '.' > org-${orgName}.json  # Make a backup JSON, for debugging

cat << "EOF"

   __ _(_) |_ ___  ___  _ __ ___   ___
  / _` | | __/ __|/ _ \| '_ ` _ \ / _ \
 | (_| | | |_\__ \ (_) | | | | | |  __/
  \__, |_|\__|___/\___/|_| |_| |_|\___|
  |___/                                
   - gitHub Info Enumerator, by savant42

Repository Enumeration Module
EOF

# Get Basic Org Infos
echo -e "
[+] Org: $orgName
"

jq '.' <<<$data
