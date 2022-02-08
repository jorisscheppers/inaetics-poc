#!/bin/bash

set -xe

mkdir /config
mkdir -p /opt/cni/bin
mkdir -p /etc/systemd/system/kubelet.service.d

#Create configs, folders and files
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

cat <<EOF | tee /config/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: 192.168.0.0/16
controllerManager:
  extraArgs:
    flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: $(docker info -f '{{.CgroupDriver}}')
EOF

#systemctl status kubelet

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

# ---
# apiVersion: kubeadm.k8s.io/v1beta2
# kind: InitConfiguration
# nodeRegistration:
#   criSocket: "unix:///run/containerd/containerd.sock


#Downloads

DOWNLOAD_DIR=/opt/bin
CNI_VERSION="v1.0.1"
CRICTL_VERSION="v1.23.0"
RELEASE_VERSION="v0.12.0"
#nslookup dl.k8s.io
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

curl() {
	command curl -sSL "$@"
}

curl "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /opt/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}


#Enable system capabilities and initialise Kubernetes components

#Enable Docker capabilities
systemctl enable docker

#enable br_netfilter module
modprobe br_netfilter
sysctl --system

#augment PATH variable with download dir
export PATH=$PATH:$DOWNLOAD_DIR

#pre-pull kubeadm images
kubeadm config images pull
wait
#init kubeadm based on /config/kubeadm-config.yaml 
kubeadm init --config /config/kubeadm-config.yaml
wait

#Enable the kubelet
systemctl enable --now kubelet
wait

#Copy .kube config to home directory so kubectl works 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

#Copy .kube config to home directory of core user so kubectl works 
mkdir -p /home/core/.kube
cp -i /etc/kubernetes/admin.conf /home/core/.kube/config
chmod 744 /home/core/.kube/config

cilium install
wait

kubectl taint nodes --all node-role.kubernetes.io/master-
#kubectl get pods -A
#kubectl get nodes -o wide

kubectl apply -f https://k8s.io/examples/application/deployment.yaml
kubectl expose deployment.apps/nginx-deployment