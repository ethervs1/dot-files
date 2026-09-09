
########################################
# DEVX SHORTCUTS
########################################
alias aws-login-dev="devx cloud aws-login -r "arn:aws:iam::789659335040:role/bamazon-teamengds" -s 43200 -p ESQOI_DEV"
alias aws-login-prod="devx cloud aws-login -r "arn:aws:iam::141988508569:role/bamazon-teamengds" -s 43200 -p ESQOI_PROD"
alias claude-login="devx cloud aws-login -y 68b5b87a53d8ed8fb0ae176c -r "arn:aws:iam::364073565765:role/ServiceAccess" -s 43200"
alias kctx="kubectl config current-context"      # Get current context
alias kctxs="kubectl config get-contexts"     # List contexts (duplicate shortcut)
alias klist="kubectl config get-clusters | sort | less"  # List known clusters
alias klogin="devx login"                     # Login via devx
alias kmariner="devx mariner kubeconfig"      # Pull kubeconfig via devx mariner
alias ksumm="kubectl config view --minify" # Summary of current context and current namespace
alias sapps="sh /Users/raul.munoz/Documents/git/dot-files/work/apps.sh"
# disable aws pager
export AWS_PAGER=""

dhelp() {
  # Display help for custom Kubernetes context/config shortcuts
  cat << 'EOF'


==========================================
KUBERNETES CONTEXT / DEVX SHORTCUTS - HELP
==========================================

CLAUDE
------
claude-login        # Login on bedrock for use Claude

DEVX
----
klogin               # Login via devx
kmariner             # Pull kubeconfig via devx mariner


KUBECONFIG / CONTEXT
--------------------
klist                # List known clusters
kctx                 # Get current context
kctxs                # List contexts
ksumm                # Summary of current context and current namespace


EOF
}
