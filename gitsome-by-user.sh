#!/bin/bash
# GraphQL Query to pull user info from GitHub.com's Public API
# Reqs: curl, jq, Github Token in GITHUB_TOKEN env var
#
# example: ./$0 githubUsername

# todo: allow-list for safe characters only
username="$1" 

# Exit if GITHUB_TOKEN is not set
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Must provide GITHUB_TOKEN in environment" 1>&2
    exit 1
fi

# GraphQL Request to GitHub.com's API
data=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -s -d @- https://api.github.com/graphql << GQL
{ "query": "
  query GetUserDetails {
    user(login: \"$username\") {
      login
      company
      email
      location
      followers {
        totalCount
      }
      following {
        totalCount
      }
      gists(first: 100, orderBy: { field: CREATED_AT, direction: DESC }) {
        totalCount
        edges {
          node {
            name
            description
            url
            files {
              encodedName
              language {
                name
              }
              size
            }
            stargazers(first: 100) {
              totalCount
            }
            updatedAt
          }
        }
      }
      gistComments(first: 100) {
        totalCount
        nodes {
          author {
            login
            url
          }
          id
          body
          createdAt
          updatedAt
          gist {
            id
            url
          }
        }
      }
      repositories(first: 100, orderBy: { field: CREATED_AT, direction: DESC }) {
        totalCount
        pageInfo {
          endCursor
          hasNextPage
        }
        edges {
          node {
            name
              owner {
                login
              }
            id
            description
            diskUsage
            url
            sshUrl
            forkCount
            hasWikiEnabled
            homepageUrl
            isInOrganization
            isEmpty
            stargazerCount
            visibility
            isFork
            openGraphImageUrl
          }
        }
      }
    }
  }
" }
GQL
)

## Uncomment out this next line to save the JSON
echo $data | jq '.' > $username.json  # Make a backup JSON, for debugging

cat << "EOF"

   __ _(_) |_ ___  ___  _ __ ___   ___
  / _` | | __/ __|/ _ \| '_ ` _ \ / _ \
 | (_| | | |_\__ \ (_) | | | | | |  __/
  \__, |_|\__|___/\___/|_| |_| |_|\___|
  |___/                                
by savant42
EOF
echo -e "gitSome - gitHub Info Enumerator, by savant42 - $(date)\n"
echo "User Enumeration Module"
# Get Basic user Infos
echo -e "\n[+] User Enumeration: $username"
jq -r '.data[] | "Login: \(.login)
Email: \(.email)
Location: \(.location)
Company: \(.company)
Following: \(.following[])
Followers: \(.followers[])
Total Repositories: \(.repositories.totalCount)
Total Gists: \(.gists.totalCount)
Total Gist Comments: \(.gistComments.totalCount)"' <<<$data

# Get info about user's Repositories
echo -e "\n[+] Repositories for $username: $(jq -r '.data.user.repositories.totalCount' <<<$data) \n---"
jq -r '.data.user.repositories.edges[].node |
"Repository Name: \(.name)
Description: \(.description)
Disk Usage: \(.diskUsage)
HTTPS URL: \(.url) 
SSH URL: \(.sshUrl)
Homepage: \(.homepageUrl)
GitWiki: \(.hasWikiEnabled)
Stargazer Count: \(.stargazerCount)
Is In Org: \(.isInOrganization)
Fork Count: \(.forkCount)
Is Fork: \(.isFork)
Is Empty: \(.isEmpty)
---"' <<<$data

# Print list of git clone URLs for all of user's repos
echo -e "\n[+] Repos Clone URL List (HTTPS):\n---"
jq -r '.data.user.repositories.edges[].node | "\(.url).git"' <<<$data

# Get info about user's Gists
echo -e "\n[+] Gists from $username: $(jq -r '.data.user.gists.totalCount' <<<$data) \n"
jq -r '.data.user.gists.edges[].node | 
"Gist ID: \(.name)
URL: \(.url)
Filename: \(.files[].encodedName)
Language: \(.files[].language.name)
Description: \(.description)
Size: \(.files[].size)
---"' <<<$data

# Get info about user's Gist Comments
echo -e "\n[+] Gist Comments from $username: $(jq -r '.data.user.gistComments.totalCount' <<<$data) \n"
jq -r '.data.user.gistComments.nodes[] | 
"Gist Comment: \(.gist.url)
Created: \(.createdAt)
Updated: \(.updatedAt)
Body: \(.body)
---"' <<<$data

# Fin
echo -e "\n[+] END $username\n"
