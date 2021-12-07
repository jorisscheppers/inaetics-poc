systemctl enable docker
modprobe br_netfilter

touch /etc/modules-load.d/k8s.conf
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

touch /etc/sysctl.d/k8s.conf
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system