
# -------------------------
# KUBECTL ALIASES
# -------------------------

alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deploy"
alias kgn="kubectl get nodes"
alias kdp="kubectl describe pod"
alias kds="kubectl describe svc"
alias kaf="kubectl apply -f"
alias kdel="kubectl delete -f"
alias kctx="kubectl config current-context"
alias kns="kubectl config set-context --current --namespace"

# -------------------------
# KUBERNETES HELP FUNCTION
# -------------------------

khelp() {
  cat << 'EOF'
====================================
      KUBECTL ALIAS QUICK GUIDE
====================================

BASICS
  k        kubectl
  kctx     Show current context
  kns      Set namespace (current context)

GET RESOURCES
  kgp      Get pods
  kgs      Get services
  kgd      Get deployments
  kgn      Get nodes

DESCRIBE
  kdp      Describe pod
  kds      Describe service

APPLY / DELETE
  kaf      Apply config file   (kubectl apply -f)
  kdel     Delete config file  (kubectl delete -f)

TIP:
  Use -n <namespace> at the end for specific namespaces
  Example: kgp -n staging

EOF
}
