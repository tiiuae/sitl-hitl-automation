#!/bin/bash
set -eu

# check an input take the build_info.json file
if [ -z "$1" ]; then
  echo "usage: $0 [output_file.json]"
  exit 1
fi

repo=$(basename `git rev-parse --show-toplevel`)
sha=$(git rev-parse --short HEAD)

# github variables are set only in github
if [ -z "${GITHUB_SERVER_URL:-}" ] || [ -z "${GITHUB_REPOSITORY:-}" ] || [ -z "${GITHUB_RUN_ID:-}" ]; then
	build_url="undefined"
else
	build_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi


# associative array of sha and build_url
declare -A build_info
build_info["reponame"]=${repo}
build_info["sha"]=${sha}
build_info["build_url"]=${build_url}

# loop thru associative array and print key value pairs
json_info="{"
for key in "${!build_info[@]}"; do
    json_info+=$(echo "\"$key\": \"${build_info[$key]}\",")
    echo $key: ${build_info[$key]}
done
json_info="${json_info%,} }"

echo "json_info: ${json_info}"
echo ${json_info} | jq .>${1}


