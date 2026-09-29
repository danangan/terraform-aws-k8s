locals {
  # Node group taint effects, in Kubernetes' spelling
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }
}

# A chart rather than kubernetes_manifest, which needs Auto Mode's CRDs
# (NodePool, IngressClassParams) to exist at plan time
resource "helm_release" "this" {
  name  = "auto-mode-config"
  chart = "${path.module}/chart"

  values = [yamlencode({
    gpuNodePool = {
      instanceType = var.gpu_instance_type
      gpuLimit     = var.gpu_limit
      taints = [for taint in values(var.gpu_node_taints) : {
        key    = taint.key
        value  = taint.value
        effect = local.taint_effects[taint.effect]
      }]
    }
  })]
}
