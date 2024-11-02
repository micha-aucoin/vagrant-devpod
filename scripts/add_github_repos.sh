#!/bin/bash

SSH_PUB_KEY=$(cat /home/vagrant/.ssh/${SSH_NAME}.pub)

JSON_PAYLOAD=$(jq -n \
  --arg key "$SSH_PUB_KEY" \
  --arg title "${SSH_NAME}" \
  '{"title": $title, "key": $key}')

# Add SSH key to GitHub account via API
RESPONSE=$(curl -sL \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "$JSON_PAYLOAD" \
  "https://api.github.com/user/keys")

echo $RESPONSE | jq '.'
echo $RESPONSE | jq '.id' > /home/vagrant/.ssh/github_key_id

# Add GitHub's host key to known_hosts to prevent host verification issues
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Start the SSH agent and add your SSH key
eval $(ssh-agent -s)
ssh-add ~/.ssh/${SSH_NAME}

# Clone the repository
eval $GIT_COMMANDS
