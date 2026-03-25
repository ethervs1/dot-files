
# -------------------------
# PODMAN ALIASES
# -------------------------

alias p='podman'

# BUILD / RUN / PULL
alias pbuild='podman build'
alias pr='podman run'
alias pp='podman pull'

# LIST
alias pps='podman ps'
alias ppsa='podman ps -a'
alias psl="podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
alias pi='podman images'
alias ppod='podman pod ps'

# START / STOP / RESTART
alias pstart='podman start'
alias pstop='podman stop'
alias prestart='podman restart'

# REMOVE
alias prm='podman rm'
alias prmi='podman rmi'
alias ppodrm='podman pod rm'

# LOGS / DEBUG
alias pl='podman logs'
alias plf='podman logs -f'
alias pexec='podman exec -it'
alias pstats='podman stats'
alias ptop='podman top'
alias pinspect='podman inspect'

# SYSTEM
alias pinfo='podman info'
alias pprune='podman system prune -f'

# -------------------------
# PODMAN CLEAN UP
# -------------------------

pclean() {
    echo "Stopping all running podman containers..."
    podman stop $(podman ps -q) 2>/dev/null

    echo "Killing all podman containers..."
    podman rm -f $(podman ps -aq) 2>/dev/null

    echo "Deleting all podman images..."
    podman rmi -f $(podman images -q) 2>/dev/null

    podman network rm $(podman network ls -q) 2>/dev/null
    podman volume rm $(podman volume ls -q) 2>/dev/null

    podman system prune -f

    echo "All podman containers stopped, removed, and images deleted."
}

# -------------------------
# PODMAN HELP FUNCTION
# -------------------------

phelp() {
  clear
  cat << 'EOF'
====================================
        PODMAN ALIAS QUICK GUIDE
====================================

BASICS
  p        podman
  pinfo    Show podman info

BUILD / RUN / PULL
  pbuild   Build image
  pr       Run container
  pp       Pull image

LIST
  pps      List running containers
  ppsa     List all containers
  psl      Pretty formatted list
  pi       List images
  ppod     List pods

START / STOP / RESTART
  pstart   Start container
  pstop    Stop container
  prestart Restart container

REMOVE
  pclean   DESTROY ALL PODMAN RELATED OBJECTS IN THE SYSTEM (containers, images, network, etc...)
  ppodrm   Remove pod
  prm      Remove container
  prmi     Remove image

LOGS / DEBUG
  pl       Show logs
  plf      Follow logs (real-time)
  pexec    Exec into container (interactive)
  pstats   Resource usage
  ptop     Processes inside container
  pinspect Inspect container/image

SYSTEM
  pprune   Remove unused data (force)

------------------------------------
EXAMPLES

Run nginx:
  pr -d --name web -p 8080:80 nginx

Enter container:
  pexec web bash

Follow logs:
  plf web

Pretty list:
  psl

EOF
}