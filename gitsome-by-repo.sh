#!/bin/bash
# GraphQL Query to pull repository info from GitHub.com's Public API
# Reqs: curl, jq, Github Token in GITHUB_TOKEN env var
#
# example: ./$0 owner repository
# todo: allow-list for safe characters only

# Org or user that owns the repo, default to thesavant42/gitsome
OWNER="${1:-thesavant42}"
REPONAME="${2:-gitsome}"

# Exit if GITHUB_TOKEN is not set
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Must provide GITHUB_TOKEN in environment" 1>&2
    exit 1
fi

# GraphQL Request to GitHub.com's API
data=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -s -d @- https://api.github.com/graphql << GQL
{ "query": "
  query {
    repository(owner: \"$OWNER\", name: \"$REPONAME\") {
      id
      nameWithOwner
      description
      url
      homepageUrl
      mirrorUrl
      projectsUrl
      projects(last: 100){
        totalCount
      }
      contactLinks {
        name
        url
        about
      }
      diskUsage
      hasWikiEnabled
      codeOfConduct {
        name
        url
      }
      hasVulnerabilityAlertsEnabled
      isArchived
      isBlankIssuesEnabled
      isDisabled
      isEmpty
      isInOrganization
      isLocked
      isMirror
      isPrivate
      isSecurityPolicyEnabled
      isTemplate
      isUserConfigurationRepository
      isFork
      hasProjectsEnabled
      hasIssuesEnabled
      pullRequests(last: 100) {
        totalCount
        nodes {
          author{
            login
            url
            resourcePath
          }
          bodyText
        }
      }
      assignableUsers(last: 100) {
        totalCount
        nodes {
          name
          login
          email
          company
          location
          pronouns
          status {
            message
            emoji
          }
          topRepositories(last: 100, orderBy: {field: UPDATED_AT, direction: DESC}){
            totalCount
            edges{
              node{
                name
                description
                url
              }
            }
          }
          repositories(first: 100, orderBy: { field: UPDATED_AT, direction: DESC}){
            totalCount
            edges{
              node{
                name
              }
            }
          }
          gists(last: 100, orderBy: { field: CREATED_AT, direction: DESC }) {
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
            updatedAt
          }
        }
      }
        }
      }
      issues(last: 25) {
        totalCount
        edges {
          node {
            number
            title
            author {
              login
            }
            bodyText
            bodyUrl
            createdAt
            lastEditedAt
            closed
          }
        }
      }
      forkCount
      refs(last: 25, refPrefix:\"refs/heads/\") {
        totalCount
        pageInfo {
          hasNextPage
        }
        edges {
          node {
            name
            target {
              ... on Commit {
                history(first: 5) {
                  edges {
                    node {
                      messageHeadline
                      committedDate
                      author {
                        name
                        email
                      }
                    }
                  }
                }
              }  
            }
          }
        }
      }
      packages(last: 100) {
        totalCount
      }
      releases(last: 100) {
        totalCount
        nodes {
          name
          url
          author {
            name
            login
            email
          }
          createdAt
          description
          isDraft
          isLatest
          isPrerelease
          databaseId
          resourcePath
        }
      }
      stargazerCount
      stargazers(last: 10){
        totalCount
        nodes {
          name
          login
          email
          company
          url
        }
      }
    }
  }
" }
GQL
)

## Uncomment out this next line to save the JSON
echo $data | jq '.' > ${OWNER}-${REPONAME}.json  # Make a backup JSON, for debugging

cat << "EOF"

   __ _(_) |_ ___  ___  _ __ ___   ___
  / _` | | __/ __|/ _ \| '_ ` _ \ / _ \
 | (_| | | |_\__ \ (_) | | | | | |  __/
  \__, |_|\__|___/\___/|_| |_| |_|\___|
  |___/                                
   - gitHub Info Enumerator, by savant42

Repository Enumeration Module
EOF

# Get Basic Repo Infos
echo -e "
[+] Repository: $REPONAME
Owner: $OWNER
"

jq -r '.data.repository |"
Name (with Owner): \(.nameWithOwner)
ID: \(.id)
Description: \(.description)
URL: \(.url)
Homepage: \(.homepageUrl)
Mirror URL: \(.mirrorUrl)
Projects URL: \(.projectsUrl)
Projects Count: \(.projects.totalCount)
"' <<<$data

echo -e "Assignable Users: $(jq -r .data.repository.assignableUsers.totalCount <<<$data)"

# assignableUsers
jq -r '.data.repository.assignableUsers.nodes[]|
"Assignable User Login: \(.login)", 
"Assignable User Gists:", "\(.gists.edges[].node| "Name: \(.name)", "URL: \(.url)", "Description: \(.description)", "")",
""
' <<<$data
