URL=$(kubectl config view -ojsonpath='{.clusters[0].cluster.server}')
prefix="https://"
short_url=${URL#"$prefix"}
cat <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: $short_url
    token: $(kubeadm token create)
    caCertHashes:
    - sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
controlPlane:
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
EOF