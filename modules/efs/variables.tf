variable "cluster_name" {
  description = "Name of the EKS cluster to install the EFS CSI driver into"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version of the cluster - used to look up the most recent add-on version for it"
  type        = string
}

variable "addon_version" {
  description = "Version of the aws-efs-csi-driver add-on to install. Defaults to the most recent one for kubernetes_version"
  type        = string
  default     = null
}
