#!/usr/bin/env sh

# Reconfigure git remotes (origin -> Source, plus Parent for forks) without
# aborting when a remote is absent, gh is unavailable/unauthenticated, or a
# git command fails. Every destructive step is guarded and warned.

if ! command -v git >/dev/null 2>&1; then
	echo "[Remote] WARN: git binary not found on PATH - skipping remote reconfiguration." >&2
	exit 0
fi

Current=$(\cd -- "$(\dirname -- "$0")" > /dev/null 2>&1 && \pwd)

# shellcheck disable=SC1091
. "$Current/../Cache.sh"

Fn

Remote() {
	git remote get-url "$1" 2> /dev/null || git remote get-url origin 2> /dev/null
}

# Remove a remote only when it actually exists; a failed removal is warned
# and ignored instead of aborting the rest of the reconfiguration.
RemoveRemoteIfPresent() {
	Name="$1"
	if git remote get-url "$Name" >/dev/null 2>&1; then
		if ! git remote remove "$Name"; then
			echo "[Remote] WARN: could not remove remote '$Name' - continuing." >&2
		fi
	fi
}

Source=$(Remote Source | \sed 's/git@github.com:/ssh:\/\/git@github.com\//')

if [ -z "$Source" ]; then
	echo "[Remote] WARN: no Source or origin remote URL could be resolved - skipping reconfiguration." >&2
	exit 0
fi

\echo "Source: "
\echo "$Source"

RemoveRemoteIfPresent origin
RemoveRemoteIfPresent Source

git remote add Source "$Source"
git remote set-url Source "$Source"

# gh is optional: an absent or unauthenticated CLI must not fail the setup.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
	gh repo set-default "$(git remote get-url Source)" || \
		echo "[Remote] WARN: gh repo set-default failed - continuing." >&2
else
	echo "[Remote] WARN: gh CLI unavailable or unauthenticated - skipping default-repo selection." >&2
fi

# shellcheck disable=SC2154
Parent="$OwnerParent/$NameParent"

RemoveRemoteIfPresent Parent

if [ -n "$OwnerParent" ] && [ "$OwnerParent" != "null" ] && [ -n "$NameParent" ] && [ "$NameParent" != "null" ]; then
	Parent="ssh://git@github.com/${Parent}"
	Parent=$(\echo "$Parent" | \sed 's/\/$/\.git/')

	\echo "Parent: "
	\echo "$Parent"

	git remote add Parent "$Parent"
	git remote set-url Parent "$Parent"
fi
