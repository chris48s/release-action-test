#!/bin/bash

set -euxo pipefail

# Set up a git user
git config user.name "release[bot]"
git config user.email "actions@users.noreply.github.com"

git fetch --unshallow --tags

# Last server-YYYY-MM-DD tag
LASTTAG=$(git tag | grep server | tail -n 1)

# Find the marker in CHANGELOG.md
INSERTPOINT=$(grep -n "^\-\-\-$" CHANGELOG.md | cut -f1 -d:)
INSERTPOINT=$((INSERTPOINT+1))

# Generate a release name
RELEASENAME="server-$(date --rfc-3339=date)"

# Assemble changelog entry
rm -f temp-changes.txt
touch temp-changes.txt
{
    echo "## $RELEASENAME"
    echo ""
    git log "$LASTTAG"..HEAD --no-merges --oneline --pretty="format:- %s" --perl-regexp --author='^((?!dependabot).*)$'
    echo $'\n'
} >> temp-changes.txt

# Write the changelog
sed -i "${INSERTPOINT} r temp-changes.txt" CHANGELOG.md

# Cleanup
rm temp-changes.txt

# Run prettier (to ensure the markdown file doesn't fail CI)
npm ci
npm run prettier

# Commit + push changelog
git checkout -b "$RELEASENAME"
git add CHANGELOG.md
git commit -m "Update Changelog"
git push origin "$RELEASENAME"

# Submit a PR
TITLE="Changelog for Release $RELEASENAME"
PR_RESP=$(curl https://api.github.com/repos/"$REPO_NAME"/pulls \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    --data '{"title": "'"$TITLE"'", "body": "'"$TITLE"'", "head": "'"$RELEASENAME"'", "base": "master"}')

# Add the 'release' label to the PR
PR_API_URL=$(echo "$PR_RESP" | jq -r ._links.issue.href)
curl "$PR_API_URL" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    --data '{"labels":["release"]}'
