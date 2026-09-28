output "node_labels" {
  description = "Labels for every node group. Depends on the Helm release, so node groups that use them are created after Cilium - nodes can't become Ready without a CNI"
  value       = { cni = "cilium" }

  depends_on = [helm_release.cilium]
}
