
# -------------------------
# SSH ALIASES
# -------------------------

alias hx_wb_prod="ssh root@186.64.113.185 -p3367"
alias hx_db_prod="ssh root@186.64.113.107 -p17301"
alias hx_all_test="ssh root@186.64.113.187 -p22148"
alias skali="ssh ethervs@192.168.1.107"

alias ethdemo="ssh demo@186.64.113.247 -p26286;"

alias sconfig="void ~/.ssh/config"

shelp() {
      clear
      cat << 'EOF'
====================================
      LIST OF HOSTS
====================================

      HEXAGONO
   =============

    hx_wb_prod      # Hexagono WEB server test
    hx_db_prod      # Hexagono DB server test

    hx_all_test     # Hexagono DB server prod

      MINE
   =============

    ethdemo         # ethervs demo -- SSH key
    skali           # my kali laptop

      Open SSH Config
   =====================

    sconfig   # void ~/.ssh/config
    
EOF
}
