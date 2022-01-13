#DOWNLOAD FLUX
#curl -s https://fluxcd.io/install.sh | sudo bash

#ENABLE SYSTEM CAPABILITIES
#systemctl enable docker
#modprobe br_netfilter

#touch /etc/modules-load.d/k8s.conf
#cat <<EOF | tee /etc/modules-load.d/k8s.conf
#br_netfilter
#EOF

#touch /etc/sysctl.d/k8s.conf
#cat <<EOF | tee /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sysctl --system

#DOWNLOAD NECESSARY BINARIES + CONFIGS
#CNI_VERSION="v1.0.1"
#CRICTL_VERSION="v1.22.0"
#RELEASE_VERSION="v0.12.0"
#DOWNLOAD_DIR=/opt/bin
#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

#mkdir -p /opt/cni/bin
#mkdir -p /etc/systemd/system/kubelet.service.d

#alias curl='curl -sSL'
#curl "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
#curl "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
#curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
#curl "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#curl --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

#chmod +x {kubeadm,kubelet,kubectl}
#mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

#systemctl enable --now kubelet
#systemctl status kubelet