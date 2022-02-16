#!/bin/bash

set -xe

#Enable system capabilities and initialise Kubernetes components

#Enable Docker capabilities
systemctl enable docker

#enable br_netfilter module
modprobe br_netfilter
sysctl --system

#pre-pull kubeadm images
kubeadm config images pull
wait
#init kubeadm based on /configs/kubeadm-config.yaml 
kubeadm init --config /configs/kubeadm-config.yaml
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

#apply storageclass config
kubectl apply -f /configs/storageclass.yaml

#apply storageclass config
kubectl apply -f /configs/persistentvolume1.yaml
kubectl apply -f /configs/persistentvolume2.yaml
kubectl apply -f /configs/persistentvolume3.yaml
kubectl apply -f /configs/persistentvolume4.yaml
kubectl apply -f /configs/persistentvolume5.yaml

#install cilium CNI implementation
cilium install
wait

kubectl taint nodes --all node-role.kubernetes.io/master-

#TODO Enable hubble: it gives an error
#cilium hubble enable --ui
#wait

#deploy sample
#kubectl apply -f https://k8s.io/examples/application/deployment.yaml
#kubectl expose deployment.apps/nginx-deployment


#Create Crossplane deployment
kubectl create namespace crossplane-system

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane --namespace crossplane-system crossplane-stable/crossplane

#install IG infra
#flux bootstrap git --context default --url=https://github.com/jorisscheppers/inaetics-poc.git --branch=main --path=clusters/infra