
#!/usr/bin/env bash

ghelp() {
  local mode="$1"

  declare -A DESC
  declare -A EX

  # ---- AUTO-DOC CORE ALIASES ----

  DESC[g]="Runs git"
  EX[g]="g status"

  DESC[ga]="Stages files"
  EX[ga]="ga src/app.js"

  DESC[gaa]="Stages ALL files (new, modified, deleted)"
  EX[gaa]="gaa"

  DESC[gc]="Commit with verbose diff"
  EX[gc]='gc -m "fix bug"'

  DESC[gcam]="Stage all + commit with message"
  EX[gcam]='gcam "feat: add login"'

  DESC[gc!]="Amend last commit (edit message)"
  EX[gc!]="gc!"

  DESC[gcn!]="Amend last commit without editing message"
  EX[gcn!]="gcn!"

  DESC[gco]="Checkout branch or file"
  EX[gco]="gco main"

  DESC[gcb]="Create and checkout new branch"
  EX[gcb]="gcb feature/api"

  DESC[gsw]="Switch branch"
  EX[gsw]="gsw develop"

  DESC[gb]="List branches"
  EX[gb]="gb"

  DESC[gbd]="Delete local branch"
  EX[gbd]="gbd feature/old"

  DESC[gf]="Fetch from origin"
  EX[gf]="gf"

  DESC[gl]="Pull from remote"
  EX[gl]="gl"

  DESC[gpr]="Pull with rebase"
  EX[gpr]="gpr"

  DESC[gp]="Push current branch"
  EX[gp]="gp"

  DESC[gpsup]="Push and set upstream"
  EX[gpsup]="gpsup"

  DESC[gpf]="Force push with lease (safe force)"
  EX[gpf]="gpf"

  DESC[gm]="Merge branch into current"
  EX[gm]="gm feature/ui"

  DESC[grb]="Rebase current branch"
  EX[grb]="grb main"

  DESC[grbi]="Interactive rebase"
  EX[grbi]="grbi HEAD~3"

  DESC[gsta]="Stash changes"
  EX[gsta]="gsta"

  DESC[gstp]="Pop stash"
  EX[gstp]="gstp"

  DESC[gst]="Show git status"
  EX[gst]="gst"

  DESC[glo]="One-line compact log"
  EX[glo]="glo"

  DESC[glog]="Graph log view"
  EX[glog]="glog"

  DESC[gd]="Show working tree diff"
  EX[gd]="gd"

  DESC[gds]="Show staged diff"
  EX[gds]="gds"

  DESC[grhh]="Hard reset (DANGEROUS)"
  EX[grhh]="grhh"

  DESC[gpristine]="Hard reset + remove untracked files (NUCLEAR)"
  EX[gpristine]="gpristine"

  DESC[gwip]="Create quick WIP snapshot commit"
  EX[gwip]="gwip"

  DESC[gunwip]="Remove last WIP commit"
  EX[gunwip]="gunwip"

  DESC[nb]="Push current branch, then create & checkout new branch"
  EX[nb]='nb feature/new-api'

  # --- GIT AM (Apply Mailbox) ---
  DESC[gam]="Apply mailbox patches"
  EX[gam]="gam patch.mbox"

  DESC[gama]="Abort git am"
  EX[gama]="gama"

  DESC[gamc]="Continue git am after resolving conflicts"
  EX[gamc]="gamc"

  DESC[gams]="Skip current patch in git am"
  EX[gams]="gams"

  DESC[gamscp]="Show current patch being applied"
  EX[gamscp]="gamscp"

  # --- GIT APPLY ---
  DESC[gap]="Apply a patch"
  EX[gap]="gap changes.patch"

  DESC[gapa]="Interactive patch staging"
  EX[gapa]="gapa"

  DESC[gapt]="Apply patch with 3-way merge"
  EX[gapt]="gapt changes.patch"

  # --- GIT ADD VARIATIONS ---
  DESC[gau]="Stage only modified files (not new)"
  EX[gau]="gau"

  DESC[gav]="Stage files with verbose output"
  EX[gav]="gav src/"

  # --- BRANCH MANAGEMENT ---
  DESC[gba]="List all branches (local + remote)"
  EX[gba]="gba"

  DESC[gbD]="Force delete branch"
  EX[gbD]="gbD old-feature"

  DESC[gbg]="Show branches with deleted remote tracking"
  EX[gbg]="gbg"

  DESC[gbgd]="Delete local branches with deleted remotes"
  EX[gbgd]="gbgd"

  DESC[gbgD]="Force delete local branches with deleted remotes"
  EX[gbgD]="gbgD"

  DESC[gbl]="Show git blame ignoring whitespace"
  EX[gbl]="gbl src/app.js"

  DESC[gbm]="Rename branch"
  EX[gbm]="gbm new-name"

  DESC[gbnm]="List branches not merged to current"
  EX[gbnm]="gbnm"

  DESC[gbr]="List remote branches"
  EX[gbr]="gbr"

  # --- BISECT ---
  DESC[gbs]="Start/manage git bisect"
  EX[gbs]="gbs"

  DESC[gbsb]="Mark current commit as bad"
  EX[gbsb]="gbsb"

  DESC[gbsg]="Mark current commit as good"
  EX[gbsg]="gbsg"

  DESC[gbsn]="Mark current commit as new (for bisect)"
  EX[gbsn]="gbsn"

  DESC[gbso]="Mark current commit as old (for bisect)"
  EX[gbso]="gbso"

  DESC[gbsr]="Reset/end bisect"
  EX[gbsr]="gbsr"

  DESC[gbss]="Start bisect session"
  EX[gbss]="gbss bad-commit good-commit"

  # --- COMMIT VARIATIONS ---
  DESC[gca]="Commit all changes with verbose diff"
  EX[gca]='gca -m "fix all"'

  DESC[gca!]="Amend with all changes"
  EX[gca!]="gca!"

  DESC[gcan!]="Amend all changes without editing message"
  EX[gcan!]="gcan!"

  DESC[gcann!]="Amend all changes with current date, no edit"
  EX[gcann!]="gcann!"

  DESC[gcans!]="Amend all changes with signoff, no edit"
  EX[gcans!]="gcans!"

  DESC[gcas]="Commit all changes with signoff"
  EX[gcas]='gcas -m "signed commit"'

  DESC[gcasm]="Commit all with signoff and message"
  EX[gcasm]='gcasm "feat: add feature"'

  DESC[gcB]="Force create and checkout branch"
  EX[gcB]="gcB feature/reset"

  DESC[gcd]="Checkout develop branch"
  EX[gcd]="gcd"

  DESC[gcf]="List all git config"
  EX[gcf]="gcf"

  DESC[gcfu]="Create fixup commit"
  EX[gcfu]="gcfu abc123"

  DESC[gcl]="Clone with submodules"
  EX[gcl]="gcl https://github.com/user/repo.git"

  DESC[gclean]="Interactive clean untracked files"
  EX[gclean]="gclean"

  DESC[gclf]="Fast clone with blobless filter"
  EX[gclf]="gclf https://github.com/user/repo.git"

  DESC[gcm]="Checkout main/master branch"
  EX[gcm]="gcm"

  DESC[gcmsg]="Commit with message"
  EX[gcmsg]='gcmsg "fix: typo"'

  DESC[gcn]="Commit without editing message"
  EX[gcn]="gcn"

  DESC[gcor]="Checkout with submodules"
  EX[gcor]="gcor branch-name"

  DESC[gcount]="Show commit counts by author"
  EX[gcount]="gcount"

  # --- CHERRY-PICK ---
  DESC[gcp]="Cherry-pick commit"
  EX[gcp]="gcp abc123"

  DESC[gcpa]="Abort cherry-pick"
  EX[gcpa]="gcpa"

  DESC[gcpc]="Continue cherry-pick"
  EX[gcpc]="gcpc"

  # --- SIGNED COMMITS ---
  DESC[gcs]="Commit with GPG signature"
  EX[gcs]='gcs -m "signed"'

  DESC[gcsm]="Commit with signoff and message"
  EX[gcsm]='gcsm "feat: add auth"'

  DESC[gcss]="Commit with GPG + signoff"
  EX[gcss]='gcss -m "secure commit"'

  DESC[gcssm]="Commit with GPG, signoff, and message"
  EX[gcssm]='gcssm "feat: secure feature"'

  # --- DIFF VARIATIONS ---
  DESC[gdca]="Show cached/staged diff"
  EX[gdca]="gdca"

  DESC[gdct]="Show most recent tag"
  EX[gdct]="gdct"

  DESC[gdcw]="Show cached diff word-by-word"
  EX[gdcw]="gdcw"

  DESC[gdt]="Show files changed in a commit"
  EX[gdt]="gdt HEAD"

  DESC[gdup]="Show diff with upstream"
  EX[gdup]="gdup"

  DESC[gdw]="Show diff word-by-word"
  EX[gdw]="gdw"

  # --- FETCH ---
  DESC[gfa]="Fetch all remotes with prune"
  EX[gfa]="gfa"

  DESC[gfg]="Find files in git repo"
  EX[gfg]="gfg config"

  DESC[gfo]="Fetch from origin"
  EX[gfo]="gfo"

  # --- GUI ---
  DESC[gg]="Launch git GUI"
  EX[gg]="gg"

  DESC[gga]="Launch git GUI for amend"
  EX[gga]="gga"

  # --- PULL/PUSH HELPERS ---
  DESC[ggpull]="Pull from origin for current branch"
  EX[ggpull]="ggpull"

  DESC[ggpush]="Push to origin for current branch"
  EX[ggpush]="ggpush"

  DESC[ggsup]="Set upstream to origin for current branch"
  EX[ggsup]="ggsup"

  # --- HELP & IGNORE ---
  DESC[ghh]="Show git help"
  EX[ghh]="ghh commit"

  DESC[gignore]="Mark file as assumed unchanged"
  EX[gignore]="gignore config.local"

  DESC[gignored]="List ignored files"
  EX[gignored]="gignored"

  # --- GITK ---
  DESC[gk]="Launch gitk GUI for all branches"
  EX[gk]="gk"

  DESC[gke]="Launch gitk with reflog"
  EX[gke]="gke"

  # --- LOG VARIATIONS ---
  DESC[glg]="Log with stats"
  EX[glg]="glg"

  DESC[glgg]="Log with graph"
  EX[glgg]="glgg"

  DESC[glgga]="Log graph for all branches"
  EX[glgga]="glgga"

  DESC[glgm]="Log graph last 10 commits"
  EX[glgm]="glgm"

  DESC[glgp]="Log with stats and patches"
  EX[glgp]="glgp"

  DESC[glod]="Pretty log with absolute dates"
  EX[glod]="glod"

  DESC[glods]="Pretty log with short dates"
  EX[glods]="glods"

  DESC[gloga]="Graph log for all branches"
  EX[gloga]="gloga"

  DESC[glol]="Pretty graph log with relative dates"
  EX[glol]="glol"

  DESC[glola]="Pretty graph log all branches"
  EX[glola]="glola"

  DESC[glols]="Pretty graph log with stats"
  EX[glols]="glols"

  DESC[glp]="Pretty log formatter"
  EX[glp]="glp"

  # --- PULL UPSTREAM ---
  DESC[gluc]="Pull from upstream current branch"
  EX[gluc]="gluc"

  DESC[glum]="Pull from upstream main branch"
  EX[glum]="glum"

  # --- MERGE ---
  DESC[gma]="Abort merge"
  EX[gma]="gma"

  DESC[gmc]="Continue merge"
  EX[gmc]="gmc"

  DESC[gmff]="Fast-forward merge only"
  EX[gmff]="gmff feature"

  DESC[gmom]="Merge origin/main into current"
  EX[gmom]="gmom"

  DESC[gms]="Squash merge"
  EX[gms]="gms feature"

  DESC[gmtl]="Run merge tool"
  EX[gmtl]="gmtl"

  DESC[gmtlvim]="Run vimdiff as merge tool"
  EX[gmtlvim]="gmtlvim"

  DESC[gmum]="Merge upstream/main into current"
  EX[gmum]="gmum"

  # --- PUSH VARIATIONS ---
  DESC[gpd]="Dry-run push (preview)"
  EX[gpd]="gpd"

  DESC[gpf!]="Force push (DANGEROUS)"
  EX[gpf!]="gpf!"

  DESC[gpoat]="Push all branches and tags"
  EX[gpoat]="gpoat"

  DESC[gpod]="Delete remote branch"
  EX[gpod]="gpod old-feature"

  # --- PULL REBASE VARIATIONS ---
  DESC[gpra]="Pull rebase with autostash"
  EX[gpra]="gpra"

  DESC[gprav]="Pull rebase autostash verbose"
  EX[gprav]="gprav"

  DESC[gpristine]="Hard reset + remove untracked (NUCLEAR)"
  EX[gpristine]="gpristine"

  DESC[gprom]="Pull rebase from origin/main"
  EX[gprom]="gprom"

  DESC[gpromi]="Interactive pull rebase from origin/main"
  EX[gpromi]="gpromi"

  DESC[gprum]="Pull rebase from upstream/main"
  EX[gprum]="gprum"

  DESC[gprumi]="Interactive pull rebase from upstream/main"
  EX[gprumi]="gprumi"

  DESC[gprv]="Pull rebase verbose"
  EX[gprv]="gprv"

  DESC[gpsupf]="Push set-upstream with safe force"
  EX[gpsupf]="gpsupf"

  DESC[gpu]="Push to upstream"
  EX[gpu]="gpu"

  DESC[gpv]="Push verbose"
  EX[gpv]="gpv"

  # --- REMOTE ---
  DESC[gr]="List remotes"
  EX[gr]="gr"

  DESC[gra]="Add remote"
  EX[gra]="gra upstream https://github.com/original/repo.git"

  # --- REBASE VARIATIONS ---
  DESC[grba]="Abort rebase"
  EX[grba]="grba"

  DESC[grbc]="Continue rebase"
  EX[grbc]="grbc"

  DESC[grbd]="Rebase onto develop"
  EX[grbd]="grbd"

  DESC[grbm]="Rebase onto main"
  EX[grbm]="grbm"

  DESC[grbo]="Rebase onto specific commit"
  EX[grbo]="grbo abc123 def456"

  DESC[grbom]="Rebase onto origin/main"
  EX[grbom]="grbom"

  DESC[grbs]="Skip current rebase commit"
  EX[grbs]="grbs"

  DESC[grbum]="Rebase onto upstream/main"
  EX[grbum]="grbum"

  # --- REVERT ---
  DESC[grev]="Revert a commit"
  EX[grev]="grev abc123"

  DESC[greva]="Abort revert"
  EX[greva]="greva"

  DESC[grevc]="Continue revert"
  EX[grevc]="grevc"

  # --- REFLOG ---
  DESC[grf]="Show reflog"
  EX[grf]="grf"

  # --- RESET ---
  DESC[grh]="Reset to commit"
  EX[grh]="grh HEAD~1"

  DESC[grhk]="Reset keeping changes"
  EX[grhk]="grhk HEAD~1"

  DESC[grhs]="Soft reset (keep staged)"
  EX[grhs]="grhs HEAD~1"

  # --- REMOVE ---
  DESC[grm]="Remove files from git"
  EX[grm]="grm old-file.txt"

  DESC[grmc]="Remove from git, keep local"
  EX[grmc]="grmc config.local"

  # --- REMOTE MANAGEMENT ---
  DESC[grmv]="Rename remote"
  EX[grmv]="grmv old-name new-name"

  DESC[groh]="Hard reset to origin/current-branch"
  EX[groh]="groh"

  DESC[grrm]="Remove remote"
  EX[grrm]="grrm old-remote"

  # --- RESTORE ---
  DESC[grs]="Restore working tree files"
  EX[grs]="grs src/app.js"

  DESC[grset]="Set remote URL"
  EX[grset]="grset origin https://new-url.git"

  DESC[grss]="Restore from specific source"
  EX[grss]="grss HEAD~1 file.txt"

  DESC[grst]="Unstage files"
  EX[grst]="grst src/app.js"

  DESC[grt]="Go to repo root directory"
  EX[grt]="grt"

  DESC[gru]="Unstage files (reset --)"
  EX[gru]="gru src/app.js"

  DESC[grup]="Update all remotes"
  EX[grup]="grup"

  DESC[grv]="Show remotes verbose"
  EX[grv]="grv"

  # --- STATUS VARIATIONS ---
  DESC[gsb]="Short status with branch"
  EX[gsb]="gsb"

  DESC[gss]="Short status"
  EX[gss]="gss"

  # --- SVN ---
  DESC[gsd]="SVN dcommit"
  EX[gsd]="gsd"

  DESC[gsr]="SVN rebase"
  EX[gsr]="gsr"

  # --- SHOW ---
  DESC[gsh]="Show commit details"
  EX[gsh]="gsh abc123"

  DESC[gsps]="Show commit with signature"
  EX[gsps]="gsps abc123"

  # --- SUBMODULE ---
  DESC[gsi]="Initialize submodules"
  EX[gsi]="gsi"

  DESC[gsu]="Update submodules"
  EX[gsu]="gsu"

  # --- STASH VARIATIONS ---
  DESC[gstaa]="Apply stash"
  EX[gstaa]="gstaa stash@{0}"

  DESC[gstall]="Stash including untracked"
  EX[gstall]="gstall"

  DESC[gstc]="Clear all stashes"
  EX[gstc]="gstc"

  DESC[gstd]="Drop stash"
  EX[gstd]="gstd stash@{0}"

  DESC[gstl]="List stashes"
  EX[gstl]="gstl"

  DESC[gsts]="Show stash contents"
  EX[gsts]="gsts stash@{0}"

  # --- SWITCH ---
  DESC[gswc]="Create and switch to new branch"
  EX[gswc]="gswc feature/new"

  DESC[gswd]="Switch to develop branch"
  EX[gswd]="gswd"

  DESC[gswm]="Switch to main branch"
  EX[gswm]="gswm"

  # --- TAGS ---
  DESC[gta]="Create annotated tag"
  EX[gta]='gta v1.0.0 -m "Release 1.0"'

  DESC[gtl]="List tags matching pattern"
  EX[gtl]="gtl v1"

  DESC[gts]="Create signed tag"
  EX[gts]='gts v1.0.0 -m "Signed release"'

  DESC[gtv]="List all tags sorted"
  EX[gtv]="gtv"

  # --- UNIGNORE ---
  DESC[gunignore]="Unmark file as assumed unchanged"
  EX[gunignore]="gunignore config.local"

  # --- WORKTREE ---
  DESC[gwt]="Manage worktrees"
  EX[gwt]="gwt list"

  DESC[gwta]="Add new worktree"
  EX[gwta]="gwta ../feature-branch feature"

  DESC[gwtls]="List all worktrees"
  EX[gwtls]="gwtls"

  DESC[gwtmv]="Move worktree"
  EX[gwtmv]="gwtmv old-path new-path"

  DESC[gwtrm]="Remove worktree"
  EX[gwtrm]="gwtrm ../old-worktree"

  # --- OTHER ---
  DESC[gwch]="Show detailed commit changes"
  EX[gwch]="gwch"

  DESC[gwipe]="Hard reset + clean (destructive)"
  EX[gwipe]="gwipe"

  DESC[_g]="Fetch and pull"
  EX[_g]="_g"

  # ---- SPECIFIC QUERY MODE ----
  if [[ -n "$mode" && "$mode" != "--all" ]]; then
    if [[ -n "${DESC[$mode]}" ]]; then
      echo "🔹 $mode"
      echo "   ${DESC[$mode]}"
      echo "   Example: ${EX[$mode]}"
    else
      echo "No documentation found for alias '$mode'"
    fi
    return
  fi

  # ---- FULL LIST MODE ----
  if [[ "$mode" == "--all" ]]; then
    echo "==== ALL DOCUMENTED GIT ALIASES ===="
    for key in ${(k)DESC}; do
      printf "%-10s → %s\n" "$key" "${DESC[$key]}"
      printf "            e.g. %s\n\n" "${EX[$key]}"
    done
    return
  fi

  # ---- DEFAULT: HUMAN GUIDE ----
  cat << 'EOF'
==============================
      GIT ALIAS QUICK GUIDE
==============================

  _g      Fetch and pull

STATUS & LOGS
  gst     Status
  glo     Compact log
  glog    Graph log

BRANCHING
  gb      List branches
  gcb     New branch
  gsw     Switch branch
  gbd     Delete branch

COMMITS
  gc      Commit
  gcam    Add all + commit
  gc!     Amend commit

SYNC
  gf      Fetch
  gl      Pull
  gpr     Pull with rebase
  gp      Push
  gpsup   Push + set upstream
  gpf     Safe force push

CHANGES
  ga      Add file
  gaa     Add all
  gd      Diff
  gds     Staged diff

STASH
  gsta    Stash
  gstp    Pop stash

HISTORY REWRITE (careful)
  grb     Rebase
  grbi    Interactive rebase
  grhh    Hard reset
  gpristine Nuclear clean

WIP
  gwip    Snapshot commit
  gunwip  Undo WIP commit

More:
  ghelp --all        Full documented list
  ghelp <alias>      Explain one alias
================================
EOF
}
