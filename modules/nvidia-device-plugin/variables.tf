variable "gpu_instance_type" {
  description = "Instance type of the GPU node group - the plugin only runs on those nodes"
  type        = string
  default     = "g4dn.xlarge"
}

variable "chart_version" {
  description = "Version of the nvidia-device-plugin Helm chart"
  type        = string
  default     = "0.20.1"
}
