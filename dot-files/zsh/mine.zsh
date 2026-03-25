
alias _g="git fetch; ggpull"
alias 1pass="echo 4FtCUf6nzWNdGrfa | pbcopy"
alias bm="mariadb"
alias bp="/opt/homebrew/opt/libpq/bin/psql"
alias c='clear'
alias clean="brew update && brew upgrade && brew cleanup && brew autoremove && brew doctor"
alias del="rm -rf"
alias e='exit'
alias get_hosts="cat ~/.ssh/config | grep Host"
alias k="kubectl"
alias l='eza -lah --group-directories-first --icons'
alias list="l ~/git/bin; tree ~/git/bin"
alias nb="gp; git checkout -b "
alias o="void ~/.zshrc"
alias s="source ~/.zshrc"
alias vs="code ."

mhelp() {
  cat << 'EOF'
====================================
           MISC. ALIAS
====================================

  _g        # git fetch; ggpull
  1pass     # Copy 1password password
  bm        # mariadb
  bp        # /opt/homebrew/opt/libpq/bin/psql
  c         # clear
  clean     # brew update && brew upgrade && brew cleanup && brew autoremove && brew doctor
  del       # rm -rf
  e         # exit
  get_hosts # cat ~/.ssh/config | grep Host
  k         # kubectl
  l         # eza -lah --group-directories-first --icons
  list      # l ~/git/bin; tree ~/git/bin
  nb        # gp; git checkout -b
  o         # void ~/.zshrc
  s         # source ~/.zshrc
  vs        # code .

====================================
EOF
}
