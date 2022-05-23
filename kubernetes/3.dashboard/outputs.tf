output "admin_token" {
  value = "kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep 'kube-admin' | awk '{print $1}')"
}