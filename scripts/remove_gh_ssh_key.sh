#!/bin/bash

KEY_ID=$(cat /home/vagrant/.ssh/github_key_id)

curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/keys/$KEY_ID
curl -H "Authorization: token $GITHUB_TOKEN" -X DELETE "https://api.github.com/user/keys/$KEY_ID"
