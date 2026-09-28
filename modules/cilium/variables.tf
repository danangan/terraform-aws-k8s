variable "cluster_name" {
  description = "Name of the EKS cluster to install Cilium into"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the cluster's Kubernetes API - Cilium talks to it directly, since kube-proxy is replaced"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets Cilium may create pod ENIs in - the cluster's private subnets"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group shared by the nodes - opened for WireGuard between them"
  type        = string
}

variable "chart_version" {
  description = "Version of the cilium Helm chart"
  type        = string
  default     = "1.20.2"
}
