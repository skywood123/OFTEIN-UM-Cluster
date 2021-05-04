#!/bin/bash/

#Reference link
#https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic


#----------------------------------------------------
#INSTALLATION PREAPRATION for Kubernetes version 1.19.3
#----------------------------------------------------
# I tested this script on fresh installed Ubuntu 18.04 virtual machine.

#Run this script as root user

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


#This part is for iptables to see bridged traffic
#load br_netfilter module

modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system




#Disable Swap (this is not persistence)
swapoff -a

#adding # symbol after matching the default swap entry /swap.img in the swap file

#In a freshly install machine, the swap entry exist is start with /swap.img
#By commenting it out, swap is not enabled even after machine rebooted.
sed -i.old -e 's/\/swap.img/# &/' /etc/fstab

#Reference link
#remove any swap entry from /etc/fstab
#https://serverfault.com/questions/684771/best-way-to-disable-swap-in-linux

#Kubernetes works with container runtime(docker,containerd,CRI-O) through CRI(interface) to create containers
#In this case, we install Docker as our container runtime.

echo "*******************************************************************************"
echo "*****************************Installing Docker*********************************"
echo "*******************************************************************************"
# (Install Docker CE)
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS

apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

# Add Docker's official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add the Docker apt repository:
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
  
# Install Docker CE
apt-get update && apt-get install -y \
  containerd.io=1.2.13-2 \
  docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)
  
# Set up the Docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker

#(optional)start on boot
systemctl enable docker

echo "*******************************************************************************"
echo "*****************Installing kubeadm,kubectl,kubelet****************************"
echo "*******************************************************************************"

#Installing kubeadm,kubectl,kubelet
#kubeadm is the admin tool in managing the kubernetes cluster like joining a cluster or reset a cluster
#kubelet is a kubernetes component, responsible in communicating with api-server, report the node and job status
#kubectl is the command line tool in interacting with kubernetes clusters
#we can setup kubectl tool in any machine to interact with kubernetes clusters by supplying the corresponding 
#kubeconfig file; which is the configuration file for kubectl to find the cluster and the credentials.
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet=1.19.3-00 kubeadm=1.19.3-00 kubectl=1.19.3-00

#mark hold which will prevent the package from being automatically installed, upgraded or removed.
apt-mark hold kubelet kubeadm kubectl


#to support pods scheduling on this worker node to use NFS storage resource in the cluster
apt-get install -y nfs-common





