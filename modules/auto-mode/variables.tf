variable "gpu_instance_type" {
  description = "Instance type for the GPU node pool"
  type        = string
  default     = "g4dn.xlarge"
}

variable "gpu_limit" {
  description = "Maximum GPUs across the GPU node pool's nodes"
  type        = number
  default     = 1
}

variable "gpu_node_taints" {
  description = "Taints for the GPU node pool, in the same format as the eks sub-module's gpu_node_taints"
  type        = map(any)
  default = {
    nvidia_gpu = {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }
}
