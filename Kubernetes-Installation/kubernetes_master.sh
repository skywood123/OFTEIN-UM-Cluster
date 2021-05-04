#Installing single master node kubernetes cluster

#At master node, this command initialize the kubernetes cluster
#pod-network-cidr is the network address to be used by the CNI(Container network interface);

sudo kubeadm init --pod-network-cidr=10.144.0.0/16

#If successful, output similar with below will generated

#This is to prepare the kubeconfig file for the kubectl to interact with the kubernetes cluster with admin access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#For below, 
#this can be pasted at the worker node machine to join the kubernetes cluster.

#kubeadm join 203.80.21.30:16443 --token ykn8ek.p1wphafasdasdasd \
#    --discovery-token-ca-cert-hash sha256:335d15fa24ce5359asdasdasd


#If it is working fine, we need to deploy the CNI in the cluster, which is responsible
#for the underlying networking between the kubernetes nodes
#There are few options such as Calico, Flannel, Weave
#In this case, Calico is used as the underlying CNI.
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml



