#!/usr/bin/env bash
# Moves the Scoop manifest to the latest *published* Findy release (no drafts, no
# pre-releases). The portable ZIP is checked against the release's SHA256SUMS.txt;
# a missing file or a wrong sum stops the update and leaves the manifest as it was.
set -euo pipefail

REPO="YuraBerez/findy"
MANIFEST="bucket/findy.json"
HOME_PAGE="https://github.com/$REPO"

tag=$(gh api "repos/$REPO/releases/latest" --jq .tag_name)   # never a draft or pre-release
version="${tag#v}"
current=$( [ -f "$MANIFEST" ] && jq -r .version "$MANIFEST" || echo none )
if [ "$version" = "$current" ]; then
  echo "Already at $version"
  exit 0
fi

zip="Findy-$version-Windows-portable.zip"
if ! gh release view "$tag" --repo "$REPO" --json assets --jq '.assets[].name' | grep -qx "$zip"; then
  echo "$tag has no $zip (releases before 0.4.1 have no portable build): nothing to do"
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
gh release download "$tag" --repo "$REPO" --pattern "$zip" --pattern SHA256SUMS.txt --dir "$work"
(cd "$work" && grep -F "$zip" SHA256SUMS.txt | sha256sum -c -)
hash=$(sha256sum "$work/$zip" | cut -d' ' -f1)

# The app folder may be the archive's root or one folder inside it
top=$(unzip -Z1 "$work/$zip" | awk -F/ 'NF > 1 {print $1}' | sort -u)
exe=$(unzip -Z1 "$work/$zip" | grep -E '(^|/)Findy\.exe$' | head -n1)
[ -n "$exe" ] || { echo "No Findy.exe in $zip"; exit 1; }
extract_dir=""
[ "$exe" != "Findy.exe" ] && extract_dir="${exe%/Findy.exe}"

url="$HOME_PAGE/releases/download/v$version/$zip"
jq -n \
  --arg version "$version" --arg url "$url" --arg hash "$hash" \
  --arg home "$HOME_PAGE" --arg dir "$extract_dir" '
  {
    version: $version,
    description: "Private, local-first kanban board for a job search",
    homepage: $home,
    license: "MIT",
    notes: [
      "Findy is not code-signed yet: Windows SmartScreen may ask once (More info > Run anyway).",
      "Your board is kept in %APPDATA%\\Findy and stays when Findy is updated or uninstalled."
    ],
    architecture: { "64bit": ({ url: $url, hash: $hash } + (if $dir == "" then {} else { extract_dir: $dir } end)) },
    shortcuts: [["Findy.exe", "Findy"]],
    checkver: { github: $home },
    autoupdate: { architecture: { "64bit": { url: ($home + "/releases/download/v$version/Findy-$version-Windows-portable.zip") } } }
  }' > "$MANIFEST"
echo "Updated to $version"
