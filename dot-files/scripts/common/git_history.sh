
#!/usr/bin/env bash
# git-bitacora.sh
# Usage: git_log

ghist() {
    # Guardar y restaurar GIT_PAGER correctamente
    local orig_git_pager="${GIT_PAGER:-}"
    export GIT_PAGER=cat

    # Color output
    color() {
        local color=$1; shift
        case $color in
            red)    printf "\033[0;31m%s\033[0m\n" "$*" ;;
            green)  printf "\033[0;32m%s\033[0m\n" "$*" ;;
            yellow) printf "\033[1;33m%s\033[0m\n" "$*" ;;
            blue)   printf "\033[0;34m%s\033[0m\n" "$*" ;;
            *)      printf "%s\n" "$*" ;;
        esac
    }

    # Cleanup al salir (incluso si hay error)
    _git_log_cleanup() {
        if [[ -n "$orig_git_pager" ]]; then
            export GIT_PAGER="$orig_git_pager"
        else
            unset GIT_PAGER
        fi
    }
    trap _git_log_cleanup RETURN  # se ejecuta al hacer return (funciona en bash)

    # Check git repo
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        color red "❌ Not inside a Git repository."
        return 1
    fi

    echo "📋 GIT LOG - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════"

    # 1. Rama actual
    local current_branch
    current_branch=$(git branch --show-current)
    color blue "🛤️  Current branch: $current_branch"

    # 2. Tracking branch
    local tracking
    tracking=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "no tracking")
    color blue "🔗 Tracking remote: $tracking"

    # 3. Ahead/behind (fetch silencioso, sin abortar si falla)
    git fetch -q origin 2>/dev/null || true

    if [[ "$tracking" != "no tracking" ]]; then
        local ahead behind
        ahead=$(git rev-list --count "${tracking#*/}..HEAD" 2>/dev/null || echo 0)
        behind=$(git rev-list --count "HEAD..${tracking#*/}" 2>/dev/null || echo 0)

        if [[ $ahead -gt 0 && $behind -gt 0 ]]; then
            color yellow "⚠️  Ahead: $ahead | Behind: $behind (diverged)"
        elif [[ $ahead -gt 0 ]]; then
            color green "✅ Ahead: $ahead commits (ready to push)"
        elif [[ $behind -gt 0 ]]; then
            color yellow "⚠️  Behind: $behind commits (ready to pull)"
        else
            color green "✅ Synced with remote"
        fi
    else
        color yellow "⚠️  No remote tracking branch configured"
    fi

    # 4. Uncommitted changes
    local uncommitted
    uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ $uncommitted -gt 0 ]]; then
        color red "🔴 Uncommitted changes: $uncommitted files"
        echo "   Files:"
        git status --porcelain --untracked-files=no | sed 's/^/   /'
    else
        color green "✅ Working directory clean"
    fi

    # 5. Stashes
    local stashes
    stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    [[ $stashes -gt 0 ]] && color yellow "💾 Stashes: $stashes"

    # 6. Últimos 3 commits
    echo
    color blue "📜 Last 3 commits:"
    git log --oneline -n 3 --decorate --color=always 2>/dev/null || color yellow "No commits yet"

    # 7. Remotes
    echo
    color blue "🌐 Remotes:"
    git remote -v | sed 's/^/   /' | head -n 4

    echo "═══════════════════════════════════════════════"
    color green "Git log complete! 🎉"
}