
########################################
# DEVX SHORTCUTS
########################################
alias aws-login-dev="devx cloud aws-login -r "arn:aws:iam::789659335040:role/bamazon-teamengds" -s 43200 -p ESQOI_DEV"
alias aws-login-prod="devx cloud aws-login -r "arn:aws:iam::141988508569:role/bamazon-teamengds" -s 43200 -p ESQOI_PROD"
alias claude-login="devx cloud aws-login -y 68b5b87a53d8ed8fb0ae176c -r "arn:aws:iam::364073565765:role/ServiceAccess" -s 43200"
alias sapps="sh /Users/raul.munoz/vault/git/dot-files/work/apps.sh"
# disable aws pager
export AWS_PAGER=""

dhelp() {
  # Display help for work-specific shortcuts
  cat << 'EOF'


==========================================
WORK-SPECIFIC SHORTCUTS - HELP
==========================================

AWS
---
aws-login-dev        # Login to AWS dev environment (ESQOI_DEV)
aws-login-prod       # Login to AWS prod environment (ESQOI_PROD)

CLAUDE
------
claude-login         # Login on bedrock for use Claude

SCRIPTS
-------
sapps                # Run apps.sh script

NOTE: For general kubectl/devx aliases, use 'khelp'


EOF
}
