#!/bin/bash
#DOWNLOAD FLUX
#echo "Installing Flux"
#curl -s https://fluxcd.io/install.sh | sudo bash

#ENABLE SYSTEM CAPABILITIES
echo "BEGIN Prepping filesystem and writing k8s conf files"

mkdir /config
mkdir -p /etc/systemd/system/kubelet.service.d
mkdir -p /opt/cni/bin
mkdir -p /.kube
mkdir -p /home/core/.kube

#KUBELET
touch /etc/modules-load.d/k8s.conf
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

touch /etc/sysctl.d/k8s.conf
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
EOF

systemctl enable docker
modprobe br_netfilter
sysctl --system

#CNI
cat <<EOF | tee /config/calico.yaml
# Source: https://docs.projectcalico.org/manifests/custom-resources.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  flexVolumePath: /opt/libexec/kubernetes/kubelet-plugins/volume/exec/
EOF

#KUBEADM
touch /config/kubeadm-config.yaml
cat <<EOF | tee /config/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  podSubnet: 192.168.0.0/16
controllerManager:
  extraArgs:
    flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
EOF

echo "END Prepping filesystem and writing k8s conf files"


#DOWNLOAD NECESSARY BINARIES + CONFIGS
echo "BEGIN Downloading binaries and configs"

CNI_VERSION="v1.0.1"
CRICTL_VERSION="v1.22.0"
RELEASE_VERSION="v0.12.0"
DOWNLOAD_DIR=/opt/bin
#DEBUG
nslookup dl.k8s.io
#/DEBUG
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
#RELEASE="v1.23.1"

curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl -sSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl -sSL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

kubeadm config images pull

echo "END Downloading binaries and configs"


#START SERVICES
echo "BEGIN Starting services"

#   Kubelet
systemctl enable --now kubelet
#systemctl status kubelet

#   kubeadm init
kubeadm init --config /config/kubeadm-config.yaml
#cp -i /etc/kubernetes/admin.conf /.kube/config
cp -i /etc/kubernetes/admin.conf /home/core/.kube/config



#CREATE CNI
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl apply -f /config/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get pods -A
kubectl get nodes -o wide

echo "END Starting services"