#!/bin/bash

set -xe

mkdir /configs
mkdir -p /data/volume1
mkdir -p /data/volume2
mkdir -p /data/volume3
mkdir -p /data/volume4
mkdir -p /data/volume5
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

cat <<EOF | tee /configs/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
apiServer:
  extraArgs:
    service-node-port-range: 2000-35000
networking:
  podSubnet: 192.168.0.0/16
controllerManager:
  extraArgs:
    flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
nodePortAddresses: [10.0.0.0/20]
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: $(docker info -f '{{.CgroupDriver}}')
EOF

cat <<EOF | tee /configs/storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
EOF

cat <<EOF | tee /configs/persistentvolume1.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-storage-pv1
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/volume1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1.cluster.local
EOF

cat <<EOF | tee /configs/persistentvolume2.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-storage-pv2
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/volume2
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1.cluster.local
EOF

cat <<EOF | tee /configs/persistentvolume3.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-storage-pv3
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/volume3
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1.cluster.local
EOF

cat <<EOF | tee /configs/persistentvolume4.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-storage-pv4
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/volume4
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1.cluster.local
EOF

cat <<EOF | tee /configs/persistentvolume5.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-storage-pv5
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/volume5
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1.cluster.local
EOF

#systemctl status kubelet

# For mitigating bug in binding port to 2 interfaces when IP is not specified. Should be fixed in 1.24


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
#RELEASE="v1.21.9"
#augment PATH variable with download dir
export PATH=$PATH:$DOWNLOAD_DIR

curl() {
	command curl -sSL "$@"
}

#     fetch and install CNI, CRITCL, kubelet and kubeadm components and kubenernetes latest release
curl "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

#     fetch and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sed "s:/usr/local/bin:${DOWNLOAD_DIR}:g" | bash

#     fetch and install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
tar xzvfC cilium-linux-amd64.tar.gz /opt/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

#Install Crossplane CLI
curl "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
mv kubectl-crossplane $DOWNLOAD_DIR/

#Install Flux binary
curl https://fluxcd.io/install.sh | sed "s:/usr/local/bin:${DOWNLOAD_DIR}:g" | bash

