#!/bin/bash
set -xe

kubectl apply -f http://infra.cluster.local/configs/k3s/provider.yaml
kubectl apply -f http://infra.cluster.local/configs/k3s-workload/k3s-workload-namespace.yaml
kubectl apply -f http://infra.cluster.local/configs/k3s-workload/k3s-workload.yaml