
# -------------------------
# KUBECTL ALIASES
# -------------------------

alias k="kubectl"
alias kaf="kubectl apply -f"
alias kctx="kubectl config current-context"
alias kctxs="kubectl config get-contexts"
alias kdel="kubectl delete -f"
alias kdp="kubectl describe pod"
alias kds="kubectl describe svc"
alias kgd="kubectl get deploy"
alias kgn="kubectl get nodes"
alias kgns="kubectl get namespaces"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias klist="kubectl config get-clusters | sort | less"
alias klogin="devx login"
alias klogs="kubectl logs "
alias kmariner="devx mariner kubeconfig"
alias kns="kubectl config set-context --current --namespace"
alias kpods="kubectl get pods -n "
alias ksumm="kubectl config view --minify"

# -------------------------
# KUBERNETES PORT-FORWARD FUNCTION
# -------------------------

# Uso: kpf <pod-name> [puerto_local:puerto_pod] [namespace]
# Ejemplo básico (hace un forward del puerto 4000 y namespace selfhostedadap): kpf selfhostedadap-litellm-deployment-xxx-xxx
# Ejemplo custom: kpf mi-pod 8080:8080 mi-namespace
kpf() {
  if [ -z "$1" ]; then
    echo "Error: Debes especificar el nombre del pod."
    echo "Uso: kpf <pod-name> [puerto_local:puerto_pod] [namespace]"
    return 1
  fi

  local pod="$1"
  local ports="${2:-4000:4000}"
  local ns="${3:-selfhostedadap}"

  echo "Ejecutando: kubectl port-forward -n $ns $pod $ports"
  kubectl port-forward -n "$ns" "$pod" "$ports"
}

# -------------------------
# KUBERNETES HELP FUNCTION
# -------------------------

khelp() {
  cat << 'EOF'
====================================
      KUBECTL ALIAS QUICK GUIDE
====================================

BASICS / CONFIG
  k        kubectl
  kctx     Show current context
  kctxs    Get all contexts
  klist    Get clusters (sorted)
  kns      Set namespace (current context)
  ksumm    Summary of current context and namespace

GET RESOURCES
  kgp      Get pods
  kgs      Get services
  kgd      Get deployments
  kgn      Get nodes
  kgns     Get namespaces (Ojo: duplicado en alias)
  kpods    Get pods in namespace (kpods <namespace>)

DESCRIBE / LOGS
  kdp      Describe pod
  kds      Describe service
  klogs    Get logs (klogs <pod>)

APPLY / DELETE
  kaf      Apply config file   (kubectl apply -f)
  kdel     Delete config file  (kubectl delete -f)

PORT-FORWARD & TOOLS
  kpf      Port-forward pod (kpf <pod> [puertos] [namespace])
  klogin   devx login
  kmariner devx mariner kubeconfig

TIP:
  Use -n <namespace> at the end for specific namespaces
  Example: kgp -n staging

EOF
}