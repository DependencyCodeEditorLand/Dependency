#!/usr/bin/env sh

Fn() {
	# One named value for the gh "null" sentinel instead of repeating the
	# literal in every comparison. gh + jq are needed only for the fallback
	# path: when either is absent, resolve from git config alone with one
	# clear warning instead of four "command not found" errors.
	Null="null"
	HaveGh=0
	if command -v gh >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
		HaveGh=1
	else
		\echo "[Cache] WARN: gh and/or jq unavailable - resolving identity from git config only."
	fi

	Owner=$(git config --get Source.Owner)

	if [ -z "$Owner" ] || [ "$Owner" = "$Null" ]; then
		if [ "$HaveGh" = "1" ]; then
			Owner=$(gh repo view --json owner 2>/dev/null | jq -r '.owner.login' 2>/dev/null)
		fi

		if [ -n "$Owner" ] && [ "$Owner" != "$Null" ]; then
			git config Source.Owner "$Owner"
		else
			\echo "Could not determine Source.Owner"
			Owner=""
		fi
	fi

	Name=$(git config --get Source.Name)

	if [ -z "$Name" ] || [ "$Name" = "$Null" ]; then
		if [ "$HaveGh" = "1" ]; then
			Name=$(gh repo view --json name 2>/dev/null | jq -r '.name' 2>/dev/null)
		fi

		if [ -n "$Name" ] && [ "$Name" != "$Null" ]; then
			git config Source.Name "$Name"
		else
			\echo "Could not determine Source.Name"
			Name=""
		fi
	fi

	OwnerParent=$(git config --get Parent.Owner)

	if [ -z "$OwnerParent" ] || [ "$OwnerParent" = "$Null" ]; then
		if [ "$HaveGh" = "1" ]; then
			OwnerParent=$(gh repo view --json parent 2>/dev/null | jq -r '.parent.owner.login' 2>/dev/null)
		fi

		if [ -n "$OwnerParent" ] && [ "$OwnerParent" != "$Null" ]; then
			git config Parent.Owner "$OwnerParent"
		else
			\echo "Could not determine Parent.Owner (repo might not be a fork)."
			OwnerParent="$Null"
		fi
	fi

	NameParent=$(git config --get Parent.Name)

	if [ -z "$NameParent" ] || [ "$NameParent" = "$Null" ]; then
		if [ "$HaveGh" = "1" ]; then
			NameParent=$(gh repo view --json parent 2>/dev/null | jq -r '.parent.name' 2>/dev/null)
		fi

		if [ -n "$NameParent" ] && [ "$NameParent" != "$Null" ]; then
			git config Parent.Name "$NameParent"
		else
			\echo "Could not determine Parent.Name (repo might not be a fork)."
			NameParent="$Null"
		fi
	fi

	BranchParent=""

	BranchParentOverride=$(git config --get Parent.BranchOverride)

	if [ -n "$BranchParentOverride" ] && [ "$BranchParentOverride" != "$Null" ]; then
		BranchParent="$BranchParentOverride"

		\echo "Using override Parent.BranchOverride: $BranchParent"
	else
		BranchParent=$(git config --get Parent.Branch)

		if [ -z "$BranchParent" ] || [ "$BranchParent" = "$Null" ]; then
			if [ -n "$OwnerParent" ] && [ "$OwnerParent" != "$Null" ] \
				&& [ -n "$NameParent" ] && [ "$NameParent" != "$Null" ]; then
				\echo "Attempting to fetch default branch for parent $OwnerParent/$NameParent..."
				# An absent gh CLI must degrade to an empty value (handled
				# below) rather than a "command not found" error.
				if [ "$HaveGh" = "1" ]; then
					BranchParentFetched=$(gh repo view "$OwnerParent/$NameParent" --json defaultBranchRef 2>/dev/null | jq -r '.defaultBranchRef.name' 2>/dev/null)
				else
					BranchParentFetched=""
				fi

				if [ -n "$BranchParentFetched" ] && [ "$BranchParentFetched" != "$Null" ]; then
					BranchParent="$BranchParentFetched"

					git config Parent.Branch "$BranchParent"

					\echo "Fetched and set Parent.Branch: $BranchParent"
				else
					\echo "Could not fetch default branch for parent $OwnerParent/$NameParent."
				fi
			else
				\echo "Cannot fetch Parent.Branch: Parent Owner/Name not available."
			fi
		else
			\echo "Using existing Parent.Branch config: $BranchParent"
		fi
	fi

	\export Owner
	\export Name
	\export OwnerParent
	\export NameParent
	\export BranchParent
}

\export Fn
