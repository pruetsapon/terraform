resource "null_resource" "shell" {
  provisioner "remote-exec" {
    inline = [
      # deploy dashboard
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml",
      # set service to use nodeport
      "kubectl --namespace kubernetes-dashboard patch svc kubernetes-dashboard -p '{\"spec\": {\"type\": \"NodePort\"}}'",
      "cat <<EOF > /$HOME/nodeport_dashboard_patch.yaml",
      "spec:",
      "  ports:",
      "  - nodePort: 32000",
      "    port: 443",
      "    protocol: TCP",
      "    targetPort: 8443",
      "EOF",
      "kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard --patch \"$(cat /$HOME/nodeport_dashboard_patch.yaml)\"",
      # create admin service account
      "cat <<EOF > /$HOME/admin-sa.yml",
      "apiVersion: v1",
      "kind: ServiceAccount",
      "metadata:",
      "  name: kube-admin",
      "  namespace: kube-system",
      "EOF",
      "kubectl apply -f /$HOME/admin-sa.yml",
      # create cluster role
      "cat <<EOF > /$HOME/admin-rbac.yml",
      "apiVersion: rbac.authorization.k8s.io/v1",
      "kind: ClusterRoleBinding",
      "metadata:",
      "  name: kube-admin",
      "roleRef:",
      "  apiGroup: rbac.authorization.k8s.io",
      "  kind: ClusterRole",
      "  name: cluster-admin",
      "subjects:",
      "  - kind: ServiceAccount",
      "    name: kube-admin",
      "    namespace: kube-system",
      "EOF",
      "kubectl apply -f /$HOME/admin-rbac.yml",
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