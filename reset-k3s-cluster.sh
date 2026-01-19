#!/usr/bin/env bash

# ---- CONFIG ----
CONTROLLER="kube-controller01"
WORKERS=("kube-worker01")
USER="cam"

# ---- FUNCTIONS ----

uninstall_k3s_controller() {
  echo ">>> [controller] Uninstalling K3s on $CONTROLLER"
  ssh ${USER}@${CONTROLLER} "
    sudo /usr/local/bin/k3s-uninstall.sh || true
    sudo rm -rf /var/lib/rancher/k3s || true
    sudo rm -rf /etc/rancher/k3s || true
    sudo rm -rf /var/lib/kubelet || true
  "
  echo ">>> [controller] Done"
}

uninstall_k3s_worker() {
  local NODE=$1
  echo ">>> [worker] Uninstalling K3s on $NODE"
  ssh ${USER}@${NODE} "
    sudo /usr/local/bin/k3s-agent-uninstall.sh || true
    sudo rm -rf /var/lib/rancher/k3s || true
    sudo rm -rf /etc/rancher/k3s || true
    sudo rm -rf /var/lib/kubelet || true
  "
  echo ">>> [worker] $NODE done"
}

# ---- RUN ----

echo "=== Parallel K3s Reset ==="

# Start controller uninstall (background)
uninstall_k3s_controller &

# Start worker uninstalls (background)
for NODE in "${WORKERS[@]}"; do
  uninstall_k3s_worker "$NODE" &
done

# Wait for all background jobs to finish
wait

echo "=== All nodes finished uninstalling ==="

# OPTIONAL: Reboot all nodes
read -p "Reboot all nodes in parallel? (y/n): " REBOOT
if [[ "$REBOOT" == "y" ]]; then
  echo "Rebooting all nodes..."
  ssh ${USER}@${CONTROLLER} "sudo reboot" &
  for NODE in "${WORKERS[@]}"; do
    ssh ${USER}@${NODE} "sudo reboot" &
  done
  wait
  echo "Reboots sent."
fi

echo "Done."
