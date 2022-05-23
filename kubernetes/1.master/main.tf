resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # set environment hosts file
      "sudo cp /etc/hosts /etc/hosts_backup",
      "echo '${var.host} master.local' | sudo tee -a /etc/hosts",
      # disable selinux
      "sudo setenforce 0",
      "sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config",
      # disable swap
      "sudo sed -i '/swap/d' /etc/fstab",
      "sudo swapoff -a",
      # install kubernetes
      "cat <<EOF > /$HOME/kubernetes.repo",
      "[kubernetes]",
      "name=Kubernetes",
      "baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64",
      "enabled=1",
      "gpgcheck=1",
      "repo_gpgcheck=1",
      "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg",
      "EOF",
      "sudo cp /$HOME/kubernetes.repo /etc/yum.repos.d/kubernetes.repo",
      "sudo yum install -y kubelet kubeadm kubectl",
      # start kubelet
      "sudo systemctl enable kubelet",
      "sudo systemctl start kubelet",
      # config sysctl
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      "cat <<EOF > /$HOME/kubernetes.conf",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.bridge.bridge-nf-call-iptables = 1",
      "net.ipv4.ip_forward = 1",
      "EOF",
      "sudo cp /$HOME/kubernetes.conf /etc/sysctl.d/kubernetes.conf",
      "sudo sysctl --system",
      # install cri-o
      "OS=CentOS_7",
      "VERSION=1.22",
      "curl -L -o /$HOME/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo",
      "sudo cp /$HOME/devel:kubic:libcontainers:stable.repo /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo",
      "curl -L -o /$HOME/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo",
      "sudo cp /$HOME/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo",
      "sudo yum remove -y docker-ce docker-ce-cli containerd.io",
      "sudo yum install -y cri-o",
      # update cri-o subnet
      "sudo sed -i 's/10.85.0.0/192.168.0.0/g' /etc/cni/net.d/100-crio-bridge.conf",
      # start cri-o
      "sudo systemctl daemon-reload",
      "sudo systemctl start crio",
      "sudo systemctl enable crio",
      # deploy kubernetes
      "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket /var/run/crio/crio.sock --upload-certs --control-plane-endpoint=master.local",
      # config regular user
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      # setup pod network
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
    ]
    connection {
      type = "ssh"
      host = var.host
      user = var.username
      password = var.password
      #private_key = file("private_key.pem")
    }
  }
}