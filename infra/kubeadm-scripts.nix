# IP
# POD-NETWORK
kubeadm init --apiserver-advertise-address 192.168.99.250 --pod-network-cidr=10.32.0.0/12
kubeadm apply -f "https://cloud.weave.works/k8s/net?k8s-version=v1.11.1&env.IPALLOC_RANGE=10.32.0.0/12"