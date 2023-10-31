#!/bin/bash
set -e

KUBELET_VERSION="${1}"
KUBEADM_VERSION="${2}"
KUBECTL_VERSION="${3}"
KUBERNETES="${4}"

function k8s_cluster(){

    sudo tee /etc/modules-load.d/containerd.conf <<EOF
    overlay
    br_netfilter
EOF


    sudo modprobe overlay
    sudo modprobe br_netfilter

    sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-ip6tables = 1
EOF

    sudo sysctl --system

    sudo apt update
    sudo apt install -y containerd.io

    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml

    sudo systemctl enable containerd
    sudo systemctl restart containerd
    sudo systemctl status containerd

    sudo swapoff -a 

    curl -sL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt update

    sudo apt install -y kubelet=${KUBELET_VERSION} kubeadm=${KUBEADM_VERSION} kubectl=${KUBECTL_VERSION}
    sudo apt-mark hold kubelet kubeadm kubectl

    sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version ${KUBERNETES} >> cluster_ini.txt

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

    kubeadm token create --print-join-command >> kubeadm_token.txt

}

k8s_cluster()