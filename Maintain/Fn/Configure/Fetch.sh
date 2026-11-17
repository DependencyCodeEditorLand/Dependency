#!/usr/bin/env sh

# Fetch Source (and Parent when this repo is a fork) without failing the
# caller. A missing git binary, an unconfigured remote or an unreachable
# network must log a clear warning and degrade gracefully.
#
# Both remotes share one resolution/fetch path so the Source branch no
# longer assumes a remote that the Parent branch explicitly checked for.

FetchRemote() {
	RemoteName="$1"

	if [ -z "$RemoteName" ]; then
		echo "[Fetch] WARN: no remote name given - skipping." >&2
		return 0
	fi

	RemoteUrl=$(git remote get-url "$RemoteName" 2>/dev/null)
	if [ -z "$RemoteUrl" ]; then
		echo "[Fetch] WARN: remote '$RemoteName' not configured - skipping $RemoteName fetch." >&2
		return 0
	fi

	if ! git fetch --no-tags "$RemoteName"; then
		echo "[Fetch] WARN: 'git fetch --no-tags $RemoteName' failed (network unreachable or auth error) - continuing." >&2
	fi
}

if ! command -v git >/dev/null 2>&1; then
	echo "[Fetch] WARN: git binary not found on PATH - skipping all fetches." >&2
	exit 0
fi

FetchRemote Source
FetchRemote Parent
