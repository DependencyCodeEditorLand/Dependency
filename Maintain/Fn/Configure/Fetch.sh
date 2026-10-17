#!/usr/bin/env sh

\pwd
git fetch --no-tags Source
if git remote get-url Parent >/dev/null 2>&1 && [ -n "$(git remote get-url Parent 2>/dev/null)" ]; then
	git fetch --no-tags Parent
fi