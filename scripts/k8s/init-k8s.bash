#!/bin/bash

set -xe

systemctl enable docker
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

CNI_VERSION="v0.8.2"
CRICTL_VERSION="v1.17.0"
RELEASE_VERSION="v0.4.0"
DOWNLOAD_DIR=/opt/bin
#nslookup dl.k8s.io
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

mkdir -p /opt/cni/bin
mkdir -p /etc/systemd/system/kubelet.service.d

curl() {
	command curl -sSL "$@"
}

curl "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /opt/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

cat <<EOF | tee kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
controllerManager:
  extraArgs:
    flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
  cgroupDriver: systemd
EOF

# For explicit cgroupdriver selection
# ---
# kind: KubeletConfiguration
# apiVersion: kubelet.config.k8s.io/v1beta1
# cgroupDriver: systemd

# For explicit pod network (https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2):
# apiVersion: kubeadm.k8s.io/v1beta2
# kind: ClusterConfiguration
# networking:
#  podSubnet: "10.244.0.0/16"

export PATH=$PATH:$DOWNLOAD_DIR

kubeadm config images pull
kubeadm init --config kubeadm-config.yaml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

systemctl enable --now kubelet
#systemctl status kubelet

kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.9.4/install/kubernetes/quick-install.yaml

kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get pods -A
kubectl get nodes -o wide

kubectl apply -f https://k8s.io/examples/application/deployment.yaml
kubectl expose deployment.apps/nginx-deployment