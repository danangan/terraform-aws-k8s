# The GPU nodes' AMI has the NVIDIA driver, but not the device plugin that
# advertises nvidia.com/gpu to Kubernetes
resource "helm_release" "this" {
  name       = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = var.chart_version
  namespace  = "kube-system"

  values = [yamlencode({
    # The chart's default affinity needs Node Feature Discovery labels
    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [{
            matchExpressions = [{
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = [var.gpu_instance_type]
            }]
          }]
        }
      }
    }
  })]
}
