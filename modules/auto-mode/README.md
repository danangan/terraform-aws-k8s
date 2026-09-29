# auto-mode

Installs what [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html) doesn't create itself, from a local Helm chart ([`chart/`](chart/)), matching what the node group setup gets:

- `alb` - an IngressClass for Auto Mode's ALB controller, so Ingresses with `ingressClassName: alb` work
- `gp3` - the default StorageClass: encrypted gp3 EBS volumes that can be expanded
- `gpu` - a NodePool for GPU nodes. The built-in pools never launch GPU instances; nodes start only while a pod requests `nvidia.com/gpu`

The root module installs it when `enable_auto_mode = true`. Needs the `helm` provider configured.

## Inputs

| Name | Description | Default |
|---|---|---|
| `gpu_instance_type` | Instance type for the GPU node pool | `g4dn.xlarge` |
| `gpu_limit` | Maximum GPUs across the GPU node pool's nodes | `1` |
| `gpu_node_taints` | Taints for the GPU node pool, in the same format as the `eks` sub-module's `gpu_node_taints` | `nvidia.com/gpu=true:NoSchedule` |
