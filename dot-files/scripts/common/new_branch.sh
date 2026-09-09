
#!/usr/bin/env bash

new_branch() {
  local NEW_BRANCH="${1:-}"
  local BASE_BRANCH="${2:-main}"

  if [[ -z "$NEW_BRANCH" ]]; then
    echo "Usage: new_branch <NEW_BRANCH> [BASE_BRANCH]"
    return 1
  fi

  # Check we're inside a git repo
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ You are NOT inside a git repository."
    return 1
  fi

  echo "🔄 Fetching remote references..."
  git fetch origin || return 1

  echo "➡️  Switching to base branch: $BASE_BRANCH"
  git checkout "$BASE_BRANCH" || return 1

  echo "⬇️  Pulling latest changes from origin/$BASE_BRANCH"
  git pull origin "$BASE_BRANCH" || return 1

  echo "🌱 Creating new branch: $NEW_BRANCH from $BASE_BRANCH"
  git checkout -b "$NEW_BRANCH" || return 1

  echo "🚀 Pushing branch to remote and setting upstream"
  git push -u origin "$NEW_BRANCH" || return 1

  echo "✅ Done! You are now on '$NEW_BRANCH' based on '$BASE_BRANCH'"
}
